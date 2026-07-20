import Foundation
import VietLunarCore

public protocol PreferencesStoring: Sendable {
    func load() -> AppPreferences
    func save(_ preferences: AppPreferences) throws
    func changes() -> AsyncStream<AppPreferences>
}

/// UserDefaults is documented as thread-safe. The lock additionally keeps the
/// root value and continuation registry consistent as one adapter operation.
public final class UserDefaultsPreferencesStore: PreferencesStoring, @unchecked Sendable {
    public static let currentSchemaVersion = 1
    public static let defaultRootKey = "preferences.root"

    private let userDefaults: UserDefaults
    private let rootKey: String
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<AppPreferences>.Continuation] = [:]

    public init(
        userDefaults: UserDefaults = .standard,
        rootKey: String = UserDefaultsPreferencesStore.defaultRootKey
    ) {
        self.userDefaults = userDefaults
        self.rootKey = rootKey
    }

    public func load() -> AppPreferences {
        lock.lock()
        defer { lock.unlock() }
        return loadUnlocked()
    }

    public func save(_ preferences: AppPreferences) throws {
        let data = try JSONEncoder.sorted.encode(
            StoredPreferencesV1(
                schemaVersion: Self.currentSchemaVersion,
                preferences: preferences
            )
        )

        let listeners: [AsyncStream<AppPreferences>.Continuation]
        let didChange: Bool
        lock.lock()
        let previous = loadUnlocked()
        userDefaults.set(data, forKey: rootKey)
        didChange = previous != preferences
        listeners = didChange ? Array(continuations.values) : []
        lock.unlock()

        for listener in listeners {
            listener.yield(preferences)
        }
    }

    public func changes() -> AsyncStream<AppPreferences> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            lock.lock()
            continuations[id] = continuation
            let current = loadUnlocked()
            lock.unlock()

            continuation.yield(current)
            continuation.onTermination = { [weak self] _ in
                self?.removeContinuation(id: id)
            }
        }
    }

    private func loadUnlocked() -> AppPreferences {
        guard let data = userDefaults.data(forKey: rootKey),
              let version = try? JSONDecoder().decode(StoredVersion.self, from: data)
        else {
            return .defaultValue
        }

        switch version.schemaVersion {
        case Self.currentSchemaVersion:
            return (try? JSONDecoder().decode(StoredPreferencesV1.self, from: data))?
                .preferences ?? .defaultValue
        case 0:
            guard let legacy = try? JSONDecoder().decode(StoredPreferencesV0.self, from: data),
                  let migrated = legacy.migrated()
            else {
                return .defaultValue
            }
            persistMigrationUnlocked(migrated)
            return migrated
        default:
            return .defaultValue
        }
    }

    private func persistMigrationUnlocked(_ preferences: AppPreferences) {
        guard let data = try? JSONEncoder.sorted.encode(
            StoredPreferencesV1(
                schemaVersion: Self.currentSchemaVersion,
                preferences: preferences
            )
        ) else {
            return
        }
        userDefaults.set(data, forKey: rootKey)
    }

    private func removeContinuation(id: UUID) {
        lock.lock()
        continuations.removeValue(forKey: id)
        lock.unlock()
    }
}

private struct StoredVersion: Decodable {
    let schemaVersion: Int
}

private struct StoredPreferencesV1: Codable {
    let schemaVersion: Int
    let preferences: AppPreferences
}

private struct StoredPreferencesV0: Decodable {
    let schemaVersion: Int
    let titleStyle: String
    let showClock: Bool
    let weekStartsOnMonday: Bool
    let use24HourTime: Bool
    let dayBoundary: String

    func migrated() -> AppPreferences? {
        guard schemaVersion == 0,
              let titleFormat = MenuBarTitleFormat(legacyValue: titleStyle),
              let boundaryPolicy = CanChiDayBoundaryPolicy(rawValue: dayBoundary)
        else {
            return nil
        }

        return AppPreferences(
            titleFormat: titleFormat,
            showsClock: showClock,
            weekStart: weekStartsOnMonday ? .monday : .sunday,
            uses24HourClock: use24HourTime,
            canChiBoundaryPolicy: boundaryPolicy
        )
    }
}

private extension MenuBarTitleFormat {
    init?(legacyValue: String) {
        switch legacyValue {
        case "lunar": self = .lunarDate
        case "solarLunar": self = .solarAndLunar
        case "lunarCanChi": self = .lunarAndDayCanChi
        case "full": self = .solarLunarAndDayCanChi
        case "icon": self = .iconOnly
        default: return nil
        }
    }
}

private extension JSONEncoder {
    static var sorted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
