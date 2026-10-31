import XCTest
@testable import VietLunarCore

final class ICSHolidayParserTests: XCTestCase {
    func testParsesSingleAllDayEvent() throws {
        let calendar = try parse(
            vevent("SUMMARY:Tết Dương lịch", "DTSTART;VALUE=DATE:20260101", "DTEND;VALUE=DATE:20260102")
        )

        XCTAssertEqual(calendar.events.count, 1)
        let event = try XCTUnwrap(calendar.events.first)
        XCTAssertEqual(event.name, "Tết Dương lịch")
        XCTAssertEqual(event.kind, .official)
        XCTAssertEqual(event.firstDate, try solarDate(2026, 1, 1))
        XCTAssertEqual(event.dayCount, 1)
    }

    func testDateWithoutValueParameterAndWithoutEndIsOneDay() throws {
        let calendar = try parse(vevent("SUMMARY:Quốc khánh", "DTSTART:20260902"))

        XCTAssertEqual(calendar.events.first?.firstDate, try solarDate(2026, 9, 2))
        XCTAssertEqual(calendar.events.first?.dayCount, 1)
    }

    func testEndDateIsExclusiveAndIndexNumbersEachDay() throws {
        let calendar = try parse(
            vevent(
                "SUMMARY:Nghỉ Tết",
                "DTSTART;VALUE=DATE:20260216",
                "DTEND;VALUE=DATE:20260221"
            )
        )
        let event = try XCTUnwrap(calendar.events.first)
        XCTAssertEqual(event.dayCount, 5)
        XCTAssertEqual(event.lastDate, try solarDate(2026, 2, 20))

        let index = HolidayIndex(calendar: calendar)
        XCTAssertTrue(index.occurrences(on: try solarDate(2026, 2, 15)).isEmpty)
        XCTAssertEqual(
            index.occurrences(on: try solarDate(2026, 2, 18)),
            [HolidayOccurrence(name: "Nghỉ Tết", kind: .official, dayNumber: 3, dayCount: 5)]
        )
        XCTAssertTrue(index.isOfficialHoliday(on: try solarDate(2026, 2, 20)))
        XCTAssertFalse(index.isOfficialHoliday(on: try solarDate(2026, 2, 21)))
    }

    func testSpanIsClampedToMaximum() throws {
        let calendar = try parse(
            vevent("SUMMARY:Dài", "DTSTART;VALUE=DATE:20260101", "DTEND;VALUE=DATE:20260401")
        )

        XCTAssertEqual(calendar.events.first?.dayCount, ICSHolidayParser.maximumSpanDays)
    }

    func testEndBeforeStartFallsBackToOneDay() throws {
        let calendar = try parse(
            vevent("SUMMARY:Lỗi", "DTSTART;VALUE=DATE:20260110", "DTEND;VALUE=DATE:20260105")
        )

        XCTAssertEqual(calendar.events.first?.dayCount, 1)
    }

    func testObservanceDescriptionIsClassifiedAndOtherwiseOfficial() throws {
        let calendar = try parse(
            vevent("SUMMARY:Ngày Sách", "DTSTART;VALUE=DATE:20260421", "DESCRIPTION:Observance"),
            vevent("SUMMARY:Quốc tế Lao động", "DTSTART;VALUE=DATE:20260501", "DESCRIPTION:public"),
            vevent("SUMMARY:Không mô tả", "DTSTART;VALUE=DATE:20260601")
        )

        let kinds = Dictionary(uniqueKeysWithValues: calendar.events.map { ($0.name, $0.kind) })
        XCTAssertEqual(kinds["Ngày Sách"], .observance)
        XCTAssertEqual(kinds["Quốc tế Lao động"], .official)
        XCTAssertEqual(kinds["Không mô tả"], .official)
    }

    func testFoldedLinesAndEscapesAreResolved() throws {
        let text = [
            "BEGIN:VCALENDAR",
            "BEGIN:VEVENT",
            "SUMMARY:Ngày lễ",
            "  lớn\\; nhất\\, thật\\\\sự",
            "DTSTART;VALUE=DATE:20260101",
            "END:VEVENT",
            "END:VCALENDAR"
        ].joined(separator: "\r\n")

        let calendar = try ICSHolidayParser.parse(Data(text.utf8))

        XCTAssertEqual(calendar.events.first?.name, "Ngày lễ lớn; nhất, thật\\sự")
    }

    func testLineFeedOnlyAndByteOrderMarkAreAccepted() throws {
        let text = "\u{FEFF}BEGIN:VCALENDAR\nBEGIN:VEVENT\nSUMMARY:A\nDTSTART:20260101\nEND:VEVENT\nEND:VCALENDAR\n"

        let calendar = try ICSHolidayParser.parse(Data(text.utf8))

        XCTAssertEqual(calendar.events.map(\.name), ["A"])
    }

    func testTimedEventsAndMalformedEntriesAreSkipped() throws {
        let calendar = try parse(
            vevent("SUMMARY:Họp", "DTSTART:20260101T090000Z", "DTEND:20260101T100000Z"),
            vevent("SUMMARY:Ngày không có thật", "DTSTART;VALUE=DATE:20260231"),
            vevent("SUMMARY:", "DTSTART;VALUE=DATE:20260301"),
            vevent("DTSTART;VALUE=DATE:20260302"),
            vevent("SUMMARY:Không ngày"),
            vevent("SUMMARY:Hợp lệ", "DTSTART;VALUE=DATE:20260303")
        )

        XCTAssertEqual(calendar.events.map(\.name), ["Hợp lệ"])
    }

    func testNestedComponentsDoNotLeakIntoTheEvent() throws {
        let text = [
            "BEGIN:VCALENDAR",
            "BEGIN:VTIMEZONE",
            "DTSTART:19700101T000000",
            "END:VTIMEZONE",
            "BEGIN:VEVENT",
            "SUMMARY:Lễ",
            "DTSTART;VALUE=DATE:20260101",
            "BEGIN:VALARM",
            "SUMMARY:Nhắc",
            "DESCRIPTION:observance",
            "DTSTART;VALUE=DATE:20260105",
            "END:VALARM",
            "END:VEVENT",
            "END:VCALENDAR"
        ].joined(separator: "\r\n")

        let calendar = try ICSHolidayParser.parse(Data(text.utf8))

        XCTAssertEqual(calendar.events.count, 1)
        XCTAssertEqual(calendar.events.first?.name, "Lễ")
        XCTAssertEqual(calendar.events.first?.kind, .official)
        XCTAssertEqual(calendar.events.first?.firstDate, try solarDate(2026, 1, 1))
    }

    func testDatesOutsideSupportedYearsAreIgnored() throws {
        let calendar = try parse(
            vevent("SUMMARY:Quá xa", "DTSTART;VALUE=DATE:17991231"),
            vevent("SUMMARY:Quá xa nữa", "DTSTART;VALUE=DATE:22000101"),
            vevent("SUMMARY:Biên", "DTSTART;VALUE=DATE:21991231")
        )

        XCTAssertEqual(calendar.events.map(\.name), ["Biên"])
    }

    func testCalendarNameAndYearRange() throws {
        let text = [
            "BEGIN:VCALENDAR",
            "X-WR-CALNAME:Ngày lễ Việt Nam",
            "BEGIN:VEVENT",
            "SUMMARY:Cuối năm",
            "DTSTART;VALUE=DATE:20261231",
            "DTEND;VALUE=DATE:20270102",
            "END:VEVENT",
            "BEGIN:VEVENT",
            "SUMMARY:Đầu năm",
            "DTSTART;VALUE=DATE:20250101",
            "END:VEVENT",
            "END:VCALENDAR"
        ].joined(separator: "\r\n")

        let calendar = try ICSHolidayParser.parse(Data(text.utf8))

        XCTAssertEqual(calendar.name, "Ngày lễ Việt Nam")
        XCTAssertEqual(calendar.yearRange, 2025...2027)
        XCTAssertEqual(calendar.events.map(\.name), ["Đầu năm", "Cuối năm"])
    }

    func testCalendarWithoutNameHasNilName() throws {
        let calendar = try parse(vevent("SUMMARY:A", "DTSTART:20260101"))

        XCTAssertNil(calendar.name)
    }

    // MARK: - Recurrence

    func testYearlyRecurrenceWithCount() throws {
        let calendar = try parse(
            vevent("SUMMARY:Hằng năm", "DTSTART;VALUE=DATE:20260101", "RRULE:FREQ=YEARLY;COUNT=3")
        )

        XCTAssertEqual(calendar.events.map(\.firstDate.year), [2026, 2027, 2028])
    }

    func testYearlyRecurrenceWithUntilIsInclusive() throws {
        let calendar = try parse(
            vevent(
                "SUMMARY:Hằng năm",
                "DTSTART;VALUE=DATE:20260301",
                "RRULE:FREQ=YEARLY;UNTIL=20280301T000000Z"
            )
        )

        XCTAssertEqual(calendar.events.map(\.firstDate.year), [2026, 2027, 2028])
    }

    func testYearlyRecurrenceWithIntervalKeepsSpan() throws {
        let calendar = try parse(
            vevent(
                "SUMMARY:Hai năm một lần",
                "DTSTART;VALUE=DATE:20260101",
                "DTEND;VALUE=DATE:20260103",
                "RRULE:FREQ=YEARLY;INTERVAL=2;COUNT=3"
            )
        )

        XCTAssertEqual(calendar.events.map(\.firstDate.year), [2026, 2028, 2030])
        XCTAssertEqual(Set(calendar.events.map(\.dayCount)), [2])
    }

    func testUnboundedYearlyRecurrenceStopsAtSupportedYears() throws {
        let calendar = try parse(
            vevent("SUMMARY:Mãi mãi", "DTSTART;VALUE=DATE:21970101", "RRULE:FREQ=YEARLY")
        )

        XCTAssertEqual(calendar.events.map(\.firstDate.year), [2197, 2198, 2199])
    }

    func testFebruaryTwentyNinthSkipsCommonYears() throws {
        let calendar = try parse(
            vevent("SUMMARY:Nhuận", "DTSTART;VALUE=DATE:20240229", "RRULE:FREQ=YEARLY;COUNT=2")
        )

        XCTAssertEqual(calendar.events.map(\.firstDate.year), [2024, 2028])
    }

    func testUnsupportedRecurrenceFallsBackToSingleOccurrence() throws {
        let calendar = try parse(
            vevent("SUMMARY:Theo thứ", "DTSTART;VALUE=DATE:20260101", "RRULE:FREQ=YEARLY;BYDAY=MO"),
            vevent("SUMMARY:Hằng tháng", "DTSTART;VALUE=DATE:20260201", "RRULE:FREQ=MONTHLY;COUNT=5"),
            vevent("SUMMARY:Hỏng", "DTSTART;VALUE=DATE:20260301", "RRULE:nonsense")
        )

        XCTAssertEqual(calendar.events.count, 3)
    }

    // MARK: - Index

    func testIndexListsOfficialHolidaysBeforeObservancesThenByName() throws {
        let calendar = try parse(
            vevent("SUMMARY:B kỷ niệm", "DTSTART;VALUE=DATE:20260501", "DESCRIPTION:observance"),
            vevent("SUMMARY:Z nghỉ", "DTSTART;VALUE=DATE:20260501"),
            vevent("SUMMARY:A nghỉ", "DTSTART;VALUE=DATE:20260501")
        )
        let index = HolidayIndex(calendar: calendar)

        let names = index.occurrences(on: try solarDate(2026, 5, 1)).map(\.name)

        XCTAssertEqual(names, ["A nghỉ", "Z nghỉ", "B kỷ niệm"])
    }

    func testObservanceAloneIsNotAnOfficialHoliday() throws {
        let calendar = try parse(
            vevent("SUMMARY:Kỷ niệm", "DTSTART;VALUE=DATE:20260508", "DESCRIPTION:observance")
        )
        let index = HolidayIndex(calendar: calendar)

        XCTAssertEqual(index.occurrences(on: try solarDate(2026, 5, 8)).count, 1)
        XCTAssertFalse(index.isOfficialHoliday(on: try solarDate(2026, 5, 8)))
    }

    func testEmptyIndexHasNoHolidays() throws {
        XCTAssertTrue(HolidayIndex.empty.occurrences(on: try solarDate(2026, 1, 1)).isEmpty)
        XCTAssertFalse(HolidayIndex.empty.isOfficialHoliday(on: try solarDate(2026, 1, 1)))
    }

    // MARK: - Errors

    func testOversizedInputIsRejected() {
        let data = Data(count: ICSHolidayParser.maximumByteCount + 1)

        XCTAssertThrowsError(try ICSHolidayParser.parse(data)) {
            XCTAssertEqual($0 as? ICSHolidayParserError, .tooLarge)
        }
    }

    func testNonTextInputIsRejected() {
        XCTAssertThrowsError(try ICSHolidayParser.parse(Data([0xFF, 0xFE, 0xFD]))) {
            XCTAssertEqual($0 as? ICSHolidayParserError, .notText)
        }
    }

    func testCalendarWithoutUsableEventsIsRejected() {
        let empty = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nEND:VCALENDAR\r\n"
        XCTAssertThrowsError(try ICSHolidayParser.parse(Data(empty.utf8))) {
            XCTAssertEqual($0 as? ICSHolidayParserError, .noEvents)
        }
        XCTAssertThrowsError(try ICSHolidayParser.parse(Data("not a calendar".utf8))) {
            XCTAssertEqual($0 as? ICSHolidayParserError, .noEvents)
        }
    }

    func testTooManyEventsIsRejected() {
        let block = "BEGIN:VEVENT\nEND:VEVENT\n"
        let text = "BEGIN:VCALENDAR\n"
            + String(repeating: block, count: ICSHolidayParser.maximumEventCount + 1)
            + "END:VCALENDAR\n"

        XCTAssertThrowsError(try ICSHolidayParser.parse(Data(text.utf8))) {
            XCTAssertEqual($0 as? ICSHolidayParserError, .tooManyEvents)
        }
    }

    // MARK: - Helpers

    private func vevent(_ lines: String...) -> String {
        (["BEGIN:VEVENT"] + lines + ["END:VEVENT"]).joined(separator: "\r\n")
    }

    private func parse(_ events: String...) throws -> HolidayCalendar {
        let text = (["BEGIN:VCALENDAR", "VERSION:2.0"] + events + ["END:VCALENDAR", ""])
            .joined(separator: "\r\n")
        return try ICSHolidayParser.parse(Data(text.utf8))
    }

    private func solarDate(_ year: Int, _ month: Int, _ day: Int) throws -> SolarDate {
        try SolarDate(validatingYear: year, month: month, day: day)
    }
}
