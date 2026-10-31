import Foundation
import VietLunarCore

public enum HolidaySourceStoreError: Error, Equatable, Sendable {
    case invalidCalendar(ICSHolidayParserError)
    case storageFailure
}

public protocol HolidaySourceStoring: Sendable {
    func loadSources() -> [HolidaySource]
    func importSource(data: Data, suggestedName: String) throws -> HolidaySource
    func removeSource(id: String) throws
    /// The selected source, or nil when the user chose to show no holidays.
    func activeSourceID() -> String?
    func setActiveSourceID(_ id: String?)
    func showsObservances() -> Bool
    func setShowsObservances(_ value: Bool)
}

/// Keeps the bundled default calendar plus any `.ics` files the user imported.
///
/// Imported files are copied verbatim into `directory` as `<UUID>.ics`; their
/// display names and the selection live in UserDefaults. Everything stays on
/// this Mac. Files that no longer parse are ignored rather than reported, so a
/// damaged copy can never prevent the app from starting.
public final class FileHolidaySourceStore: HolidaySourceStoring, @unchecked Sendable {
    public static let builtInSourceID = "builtin"

    static let activeSourceKey = "holidays.activeSource"
    static let observancesKey = "holidays.showsObservances"
    static let importedNamesKey = "holidays.importedNames"

    private static let maximumNameLength = 100

    private let builtInURL: URL?
    private let directory: URL
    private let userDefaults: UserDefaults
    private let lock = NSLock()

    public static var defaultDirectory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("VietLunar", isDirectory: true)
            .appendingPathComponent("Holidays", isDirectory: true)
    }

    public init(
        builtInURL: URL?,
        directory: URL = FileHolidaySourceStore.defaultDirectory,
        userDefaults: UserDefaults = .standard
    ) {
        self.builtInURL = builtInURL
        self.directory = directory
        self.userDefaults = userDefaults
    }

    public func loadSources() -> [HolidaySource] {
        lock.lock()
        defer { lock.unlock() }

        var sources: [HolidaySource] = []
        if let builtIn = loadBuiltIn() {
            sources.append(builtIn)
        }
        sources.append(contentsOf: loadImported())
        return sources
    }

    public func importSource(data: Data, suggestedName: String) throws -> HolidaySource {
        let calendar: HolidayCalendar
        do {
            calendar = try ICSHolidayParser.parse(data)
        } catch let error as ICSHolidayParserError {
            throw HolidaySourceStoreError.invalidCalendar(error)
        } catch {
            throw HolidaySourceStoreError.storageFailure
        }

        lock.lock()
        defer { lock.unlock() }

        let id = UUID().uuidString
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL(forID: id), options: .atomic)
        } catch {
            throw HolidaySourceStoreError.storageFailure
        }

        let name = Self.sourceName(
            calendarName: calendar.name,
            suggestedName: suggestedName
        )
        var names = importedNames()
        names[id] = name
        userDefaults.set(names, forKey: Self.importedNamesKey)

        return HolidaySource(id: id, name: name, isBuiltIn: false, calendar: calendar)
    }

    public func removeSource(id: String) throws {
        // Only imported sources are removable; the UUID check also keeps a
        // crafted id from addressing anything outside the storage directory.
        guard let uuid = UUID(uuidString: id) else {
            throw HolidaySourceStoreError.storageFailure
        }
        let normalizedID = uuid.uuidString

        lock.lock()
        defer { lock.unlock() }

        let url = fileURL(forID: normalizedID)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                throw HolidaySourceStoreError.storageFailure
            }
        }

        var names = importedNames()
        names.removeValue(forKey: normalizedID)
        userDefaults.set(names, forKey: Self.importedNamesKey)

        if userDefaults.string(forKey: Self.activeSourceKey) == normalizedID {
            userDefaults.removeObject(forKey: Self.activeSourceKey)
        }
    }

    public func activeSourceID() -> String? {
        lock.lock()
        defer { lock.unlock() }

        guard let stored = userDefaults.string(forKey: Self.activeSourceKey) else {
            return Self.builtInSourceID
        }
        return stored.isEmpty ? nil : stored
    }

    public func setActiveSourceID(_ id: String?) {
        lock.lock()
        defer { lock.unlock() }

        userDefaults.set(id ?? "", forKey: Self.activeSourceKey)
    }

    public func showsObservances() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return userDefaults.bool(forKey: Self.observancesKey)
    }

    public func setShowsObservances(_ value: Bool) {
        lock.lock()
        defer { lock.unlock() }

        userDefaults.set(value, forKey: Self.observancesKey)
    }

    // MARK: - Private

    private func loadBuiltIn() -> HolidaySource? {
        guard let builtInURL,
              let data = try? Data(contentsOf: builtInURL),
              let calendar = try? ICSHolidayParser.parse(data)
        else {
            return nil
        }

        // The name stays empty: the app shows its own localized label.
        return HolidaySource(
            id: Self.builtInSourceID,
            name: calendar.name ?? "",
            isBuiltIn: true,
            calendar: calendar
        )
    }

    private func loadImported() -> [HolidaySource] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        let names = importedNames()
        var sources: [HolidaySource] = []
        for url in urls where url.pathExtension.lowercased() == "ics" {
            guard let uuid = UUID(uuidString: url.deletingPathExtension().lastPathComponent),
                  let data = try? Data(contentsOf: url),
                  let calendar = try? ICSHolidayParser.parse(data)
            else {
                continue
            }

            let id = uuid.uuidString
            sources.append(
                HolidaySource(
                    id: id,
                    name: names[id] ?? calendar.name ?? id,
                    isBuiltIn: false,
                    calendar: calendar
                )
            )
        }

        return sources.sorted { lhs, rhs in
            let order = lhs.name.localizedStandardCompare(rhs.name)
            return order == .orderedSame ? lhs.id < rhs.id : order == .orderedAscending
        }
    }

    private func importedNames() -> [String: String] {
        userDefaults.dictionary(forKey: Self.importedNamesKey) as? [String: String] ?? [:]
    }

    private func fileURL(forID id: String) -> URL {
        directory.appendingPathComponent(id).appendingPathExtension("ics")
    }

    private static func sourceName(calendarName: String?, suggestedName: String) -> String {
        if let calendarName, !calendarName.isEmpty {
            return calendarName
        }

        var name = suggestedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.lowercased().hasSuffix(".ics") {
            name = String(name.dropLast(4)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return name.isEmpty ? "ICS" : String(name.prefix(maximumNameLength))
    }
}
