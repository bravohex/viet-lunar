import Foundation

public enum ICSHolidayParserError: Error, Equatable, Sendable {
    case tooLarge
    case tooManyEvents
    case notText
    case noEvents
}

/// Minimal iCalendar reader for holiday files.
///
/// It understands only what a holiday list needs: all-day `VEVENT`s with a
/// `SUMMARY`, an optional exclusive `DTEND`, and simple yearly `RRULE`s.
/// Timed events and anything else are skipped rather than guessed at, so a
/// file is never interpreted in a way its author did not write.
public enum ICSHolidayParser {
    public static let maximumByteCount = 1_048_576
    public static let maximumEventCount = 20_000
    public static let maximumSpanDays = 31
    public static let supportedYears = 1800...2199

    private static let maximumNameLength = 200
    private static let maximumCalendarNameLength = 100

    public static func parse(_ data: Data) throws -> HolidayCalendar {
        guard data.count <= maximumByteCount else {
            throw ICSHolidayParserError.tooLarge
        }
        guard var text = String(data: data, encoding: .utf8) else {
            throw ICSHolidayParserError.notText
        }
        if text.hasPrefix("\u{FEFF}") {
            text.removeFirst()
        }

        var stack: [String] = []
        var current = RawEvent()
        var eventDepth: Int?
        var calendarName: String?
        var rawEventCount = 0
        var events: [HolidayEvent] = []

        for line in logicalLines(from: text) {
            guard let property = parseProperty(line) else {
                continue
            }

            switch property.name {
            case "BEGIN":
                let component = property.value.uppercased()
                stack.append(component)
                if component == "VEVENT", eventDepth == nil {
                    rawEventCount += 1
                    guard rawEventCount <= maximumEventCount else {
                        throw ICSHolidayParserError.tooManyEvents
                    }
                    current = RawEvent()
                    eventDepth = stack.count
                }
            case "END":
                let component = property.value.uppercased()
                if component == "VEVENT",
                   let depth = eventDepth,
                   stack.count == depth {
                    events.append(contentsOf: expand(current))
                    eventDepth = nil
                }
                if let index = stack.lastIndex(of: component) {
                    stack.removeSubrange(index...)
                }
            default:
                if let depth = eventDepth, stack.count == depth {
                    current.apply(property)
                } else if stack == ["VCALENDAR"], property.name == "X-WR-CALNAME" {
                    calendarName = displayName(
                        property.value,
                        limit: maximumCalendarNameLength
                    )
                }
            }

            guard events.count <= maximumEventCount else {
                throw ICSHolidayParserError.tooManyEvents
            }
        }

        guard !events.isEmpty else {
            throw ICSHolidayParserError.noEvents
        }

        events.sort { lhs, rhs in
            if lhs.firstDate != rhs.firstDate {
                return lhs.firstDate < rhs.firstDate
            }
            return lhs.name < rhs.name
        }

        return HolidayCalendar(name: calendarName, events: events)
    }

    // MARK: - Lines and properties

    fileprivate struct Property {
        let name: String
        let value: String
    }

    fileprivate struct RawEvent {
        var summary: String?
        var description: String?
        var start: String?
        var end: String?
        var rule: String?

        mutating func apply(_ property: Property) {
            switch property.name {
            case "SUMMARY": summary = property.value
            case "DESCRIPTION": description = property.value
            case "DTSTART": start = property.value
            case "DTEND": end = property.value
            case "RRULE": rule = property.value
            default: break
            }
        }
    }

    /// Normalizes line endings and joins folded continuation lines.
    private static func logicalLines(from text: String) -> [String] {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var lines: [String] = []
        for rawLine in normalized.split(separator: "\n", omittingEmptySubsequences: false) {
            if let first = rawLine.first,
               first == " " || first == "\t",
               !lines.isEmpty {
                lines[lines.count - 1].append(contentsOf: rawLine.dropFirst())
            } else {
                lines.append(String(rawLine))
            }
        }
        return lines
    }

    /// Splits `NAME;PARAM=x:value` at the first colon outside double quotes.
    /// Parameters are not needed for date-only holiday events, so they are
    /// dropped after the name is extracted.
    private static func parseProperty(_ line: String) -> Property? {
        var isQuoted = false
        var colon: String.Index?
        for index in line.indices {
            let character = line[index]
            if character == "\"" {
                isQuoted.toggle()
            } else if character == ":", !isQuoted {
                colon = index
                break
            }
        }
        guard let colon else {
            return nil
        }

        let head = line[..<colon]
        let nameEnd = head.firstIndex(of: ";") ?? head.endIndex
        let name = head[..<nameEnd]
            .trimmingCharacters(in: .whitespaces)
            .uppercased()
        guard !name.isEmpty else {
            return nil
        }

        let value = line[line.index(after: colon)...]
            .trimmingCharacters(in: .whitespaces)
        return Property(name: name, value: value)
    }

    // MARK: - Events

    private static func expand(_ event: RawEvent) -> [HolidayEvent] {
        guard let name = displayName(event.summary, limit: maximumNameLength),
              let startValue = event.start,
              let first = parseDate(startValue),
              supportedYears.contains(first.year)
        else {
            return []
        }

        let kind: HolidayKind = isObservance(event.description)
            ? .observance
            : .official

        var span = 1
        if let endValue = event.end, let end = parseDate(endValue) {
            let days = GregorianJDN.jdn(for: end) - GregorianJDN.jdn(for: first)
            span = min(max(days, 1), maximumSpanDays)
        }

        return occurrenceStarts(first: first, rule: event.rule).map {
            HolidayEvent(name: name, kind: kind, firstDate: $0, dayCount: span)
        }
    }

    private static func isObservance(_ description: String?) -> Bool {
        guard let description else {
            return false
        }
        return unescape(description).lowercased().contains("observance")
    }

    /// Accepts only `YYYYMMDD`; a timed value (`...T...`) is not an all-day
    /// holiday and is rejected.
    private static func parseDate(_ value: String) -> SolarDate? {
        let bytes = Array(value.utf8)
        guard bytes.count == 8,
              bytes.allSatisfy({ (48...57).contains($0) })
        else {
            return nil
        }

        func number(_ range: Range<Int>) -> Int {
            bytes[range].reduce(0) { $0 * 10 + Int($1 - 48) }
        }

        return SolarDate.valid(
            year: number(0..<4),
            month: number(4..<6),
            day: number(6..<8)
        )
    }

    // MARK: - Recurrence

    private struct YearlyRecurrence {
        let interval: Int
        let count: Int?
        let untilKey: Int?

        /// Returns nil for anything but a plain yearly rule, so unsupported
        /// rules fall back to the single dated occurrence.
        init?(_ rule: String) {
            var frequency: String?
            var interval = 1
            var count: Int?
            var untilKey: Int?

            for part in rule.split(separator: ";") {
                let pair = part.split(
                    separator: "=",
                    maxSplits: 1,
                    omittingEmptySubsequences: false
                )
                guard pair.count == 2 else {
                    return nil
                }
                let key = pair[0].uppercased()
                let value = String(pair[1])

                switch key {
                case "FREQ":
                    frequency = value.uppercased()
                case "INTERVAL":
                    guard let parsed = Int(value), (1...1_000).contains(parsed) else {
                        return nil
                    }
                    interval = parsed
                case "COUNT":
                    guard let parsed = Int(value), parsed >= 1 else {
                        return nil
                    }
                    count = parsed
                case "UNTIL":
                    guard let parsed = Self.dateKey(value) else {
                        return nil
                    }
                    untilKey = parsed
                case "WKST":
                    break
                default:
                    return nil
                }
            }

            guard frequency == "YEARLY" else {
                return nil
            }
            self.interval = interval
            self.count = count
            self.untilKey = untilKey
        }

        /// `YYYYMMDD` of the first eight characters, e.g. from `20301231T…`.
        private static func dateKey(_ value: String) -> Int? {
            let bytes = Array(value.utf8.prefix(8))
            guard bytes.count == 8,
                  bytes.allSatisfy({ (48...57).contains($0) })
            else {
                return nil
            }
            return bytes.reduce(0) { $0 * 10 + Int($1 - 48) }
        }
    }

    private static func occurrenceStarts(
        first: SolarDate,
        rule: String?
    ) -> [SolarDate] {
        guard let rule, let recurrence = YearlyRecurrence(rule) else {
            return [first]
        }

        var starts = [first]
        var year = first.year
        while true {
            if let count = recurrence.count, starts.count >= count {
                break
            }
            year += recurrence.interval
            guard supportedYears.contains(year) else {
                break
            }
            // A rule anchored on Feb 29 has no instance in common years.
            guard let candidate = SolarDate.valid(
                year: year,
                month: first.month,
                day: first.day
            ) else {
                continue
            }
            let key = candidate.year * 10_000 + candidate.month * 100 + candidate.day
            if let untilKey = recurrence.untilKey, key > untilKey {
                break
            }
            starts.append(candidate)
        }
        return starts
    }

    // MARK: - Text

    private static func displayName(_ raw: String?, limit: Int) -> String? {
        guard let raw else {
            return nil
        }
        let cleaned = unescape(raw).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            return nil
        }
        return String(cleaned.prefix(limit))
    }

    /// Resolves iCalendar TEXT escapes. A line break inside a name becomes a
    /// space so the name stays on one line.
    private static func unescape(_ value: String) -> String {
        var result = ""
        var iterator = value.makeIterator()
        while let character = iterator.next() {
            guard character == "\\" else {
                result.append(character)
                continue
            }
            guard let escaped = iterator.next() else {
                result.append(character)
                break
            }
            switch escaped {
            case "n", "N":
                result.append(" ")
            default:
                result.append(escaped)
            }
        }
        return result
    }
}
