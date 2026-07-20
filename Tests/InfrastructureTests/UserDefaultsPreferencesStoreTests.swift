import Foundation
import XCTest
import VietLunarCore
@testable import VietLunarInfrastructure

final class UserDefaultsPreferencesStoreTests: XCTestCase {
    func testEmptyStoreLoadsCentralDefaults() throws {
        let context = try makeContext()

        XCTAssertEqual(context.store.load(), .defaultValue)
        XCTAssertFalse(context.defaults.dictionaryRepresentation().keys.contains(
            UserDefaultsPreferencesStore.defaultRootKey
        ))
    }

    func testSaveRoundTripsThroughOneVersionedRootKey() throws {
        let context = try makeContext()
        let preferences = AppPreferences(
            titleFormat: .solarLunarAndDayCanChi,
            showsClock: true,
            weekStart: .sunday,
            uses24HourClock: false,
            canChiBoundaryPolicy: .startOfZiHour
        )

        try context.store.save(preferences)

        XCTAssertEqual(context.store.load(), preferences)
        let persistedKeys = context.defaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix("preferences")
        }
        XCTAssertEqual(persistedKeys, [UserDefaultsPreferencesStore.defaultRootKey])

        let data = try XCTUnwrap(
            context.defaults.data(forKey: UserDefaultsPreferencesStore.defaultRootKey)
        )
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        XCTAssertEqual(
            object["schemaVersion"] as? Int,
            UserDefaultsPreferencesStore.currentSchemaVersion
        )
        XCTAssertNil(object["menuTitle"])
        XCTAssertNil(object["loginItemStatus"])
    }

    @MainActor
    func testChangesYieldCurrentValueThenDistinctSaves() async throws {
        let context = try makeContext()
        var iterator = context.store.changes().makeAsyncIterator()

        let initial = await iterator.next()
        XCTAssertEqual(initial, .defaultValue)

        var changed = AppPreferences.defaultValue
        changed.titleFormat = .iconOnly
        try context.store.save(changed)
        let emitted = await iterator.next()
        XCTAssertEqual(emitted, changed)
    }

    func testVersionZeroPayloadMigratesForwardInPlace() throws {
        let context = try makeContext()
        let legacy = Data(
            #"{"schemaVersion":0,"titleStyle":"full","showClock":true,"weekStartsOnMonday":false,"use24HourTime":false,"dayBoundary":"startOfZiHour"}"#.utf8
        )
        context.defaults.set(
            legacy,
            forKey: UserDefaultsPreferencesStore.defaultRootKey
        )

        let migrated = context.store.load()

        XCTAssertEqual(
            migrated,
            AppPreferences(
                titleFormat: .solarLunarAndDayCanChi,
                showsClock: true,
                weekStart: .sunday,
                uses24HourClock: false,
                canChiBoundaryPolicy: .startOfZiHour
            )
        )
        let migratedData = try XCTUnwrap(
            context.defaults.data(forKey: UserDefaultsPreferencesStore.defaultRootKey)
        )
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: migratedData) as? [String: Any]
        )
        XCTAssertEqual(object["schemaVersion"] as? Int, 1)
        XCTAssertNotNil(object["preferences"])
        XCTAssertNil(object["titleStyle"])
    }

    func testCorruptUnknownAndInvalidLegacyPayloadsFailSafeWithoutDeletion() throws {
        for data in [
            Data("not-json".utf8),
            Data(#"{"schemaVersion":99,"preferences":{}}"#.utf8),
            Data(
                #"{"schemaVersion":0,"titleStyle":"unknown","showClock":true,"weekStartsOnMonday":true,"use24HourTime":true,"dayBoundary":"civilMidnight"}"#.utf8
            )
        ] {
            let context = try makeContext()
            context.defaults.set(
                data,
                forKey: UserDefaultsPreferencesStore.defaultRootKey
            )

            XCTAssertEqual(context.store.load(), .defaultValue)
            XCTAssertEqual(
                context.defaults.data(forKey: UserDefaultsPreferencesStore.defaultRootKey),
                data
            )
        }
    }

    private func makeContext() throws -> (
        defaults: UserDefaults,
        store: UserDefaultsPreferencesStore
    ) {
        let suiteName = "VietLunarTests.Preferences.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return (
            defaults,
            UserDefaultsPreferencesStore(userDefaults: defaults)
        )
    }
}
