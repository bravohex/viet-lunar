import Foundation
import XCTest
import VietLunarCore
@testable import VietLunarInfrastructure

final class FileHolidaySourceStoreTests: XCTestCase {
    func testStoreWithoutBuiltInFileStartsEmpty() throws {
        let context = try makeContext(withBuiltIn: false)

        XCTAssertTrue(context.store.loadSources().isEmpty)
    }

    func testBuiltInSourceIsLoadedFromBundledFile() throws {
        let context = try makeContext()

        let sources = context.store.loadSources()

        XCTAssertEqual(sources.map(\.id), [FileHolidaySourceStore.builtInSourceID])
        XCTAssertEqual(sources.first?.isBuiltIn, true)
        XCTAssertEqual(sources.first?.calendar.events.count, 1)
    }

    func testBuiltInSourceIsActiveByDefaultAndNoneIsRemembered() throws {
        let context = try makeContext()
        XCTAssertEqual(context.store.activeSourceID(), FileHolidaySourceStore.builtInSourceID)

        context.store.setActiveSourceID(nil)
        XCTAssertNil(context.store.activeSourceID())
        XCTAssertNil(context.makeStore().activeSourceID())

        context.store.setActiveSourceID("custom")
        XCTAssertEqual(context.makeStore().activeSourceID(), "custom")
    }

    func testImportedSourcePersistsAcrossStoreInstances() throws {
        let context = try makeContext()

        let imported = try context.store.importSource(
            data: Data(sampleCalendar(name: "Nhật Bản").utf8),
            suggestedName: "japan.ics"
        )

        XCTAssertFalse(imported.isBuiltIn)
        XCTAssertEqual(imported.name, "Nhật Bản")
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: context.directory.appendingPathComponent("\(imported.id).ics").path
            )
        )

        let reloaded = context.makeStore().loadSources()
        XCTAssertEqual(reloaded.map(\.id), [FileHolidaySourceStore.builtInSourceID, imported.id])
        XCTAssertEqual(reloaded.last?.name, "Nhật Bản")
        XCTAssertEqual(reloaded.last?.calendar, imported.calendar)
    }

    func testImportedNameFallsBackToFileNameWithoutExtension() throws {
        let context = try makeContext()

        let named = try context.store.importSource(
            data: Data(sampleCalendar().utf8),
            suggestedName: "  Hàn Quốc 2026.ICS "
        )
        let unnamed = try context.store.importSource(
            data: Data(sampleCalendar().utf8),
            suggestedName: "   "
        )

        XCTAssertEqual(named.name, "Hàn Quốc 2026")
        XCTAssertEqual(unnamed.name, "ICS")
    }

    func testImportedSourcesAreSortedByName() throws {
        let context = try makeContext(withBuiltIn: false)
        _ = try context.store.importSource(data: Data(sampleCalendar().utf8), suggestedName: "Zebra")
        _ = try context.store.importSource(data: Data(sampleCalendar().utf8), suggestedName: "Alpha")

        XCTAssertEqual(context.store.loadSources().map(\.name), ["Alpha", "Zebra"])
    }

    func testInvalidImportThrowsAndStoresNothing() throws {
        let context = try makeContext()

        XCTAssertThrowsError(
            try context.store.importSource(
                data: Data("BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n".utf8),
                suggestedName: "empty.ics"
            )
        ) {
            XCTAssertEqual($0 as? HolidaySourceStoreError, .invalidCalendar(.noEvents))
        }
        XCTAssertThrowsError(
            try context.store.importSource(data: Data([0xFF, 0xFE]), suggestedName: "bin.ics")
        ) {
            XCTAssertEqual($0 as? HolidaySourceStoreError, .invalidCalendar(.notText))
        }

        XCTAssertEqual(context.store.loadSources().count, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: context.directory.path))
        XCTAssertNil(context.defaults.object(forKey: FileHolidaySourceStore.importedNamesKey))
    }

    func testRemovingActiveImportedSourceFallsBackToDefault() throws {
        let context = try makeContext()
        let imported = try context.store.importSource(
            data: Data(sampleCalendar().utf8),
            suggestedName: "x.ics"
        )
        context.store.setActiveSourceID(imported.id)

        try context.store.removeSource(id: imported.id)

        XCTAssertEqual(context.store.activeSourceID(), FileHolidaySourceStore.builtInSourceID)
        XCTAssertEqual(context.store.loadSources().map(\.id), [FileHolidaySourceStore.builtInSourceID])
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: context.directory.appendingPathComponent("\(imported.id).ics").path
            )
        )
        XCTAssertTrue(
            (context.defaults.dictionary(forKey: FileHolidaySourceStore.importedNamesKey) ?? [:]).isEmpty
        )
    }

    func testRemovingAnotherSourceKeepsTheSelection() throws {
        let context = try makeContext()
        let first = try context.store.importSource(data: Data(sampleCalendar().utf8), suggestedName: "a")
        let second = try context.store.importSource(data: Data(sampleCalendar().utf8), suggestedName: "b")
        context.store.setActiveSourceID(first.id)

        try context.store.removeSource(id: second.id)

        XCTAssertEqual(context.store.activeSourceID(), first.id)
    }

    func testRemoveRejectsBuiltInAndNonUUIDIdentifiers() throws {
        let context = try makeContext()

        for id in [FileHolidaySourceStore.builtInSourceID, "../outside", ""] {
            XCTAssertThrowsError(try context.store.removeSource(id: id)) {
                XCTAssertEqual($0 as? HolidaySourceStoreError, .storageFailure)
            }
        }
        XCTAssertEqual(context.store.loadSources().map(\.id), [FileHolidaySourceStore.builtInSourceID])
    }

    func testDamagedAndForeignFilesAreIgnored() throws {
        let context = try makeContext()
        let valid = try context.store.importSource(data: Data(sampleCalendar().utf8), suggestedName: "ok")
        let fileManager = FileManager.default
        try Data("garbage".utf8).write(
            to: context.directory.appendingPathComponent("\(UUID().uuidString).ics")
        )
        try Data(sampleCalendar().utf8).write(
            to: context.directory.appendingPathComponent("not-a-uuid.ics")
        )
        try Data(sampleCalendar().utf8).write(
            to: context.directory.appendingPathComponent("\(UUID().uuidString).txt")
        )
        XCTAssertEqual(try fileManager.contentsOfDirectory(atPath: context.directory.path).count, 4)

        XCTAssertEqual(
            context.store.loadSources().map(\.id),
            [FileHolidaySourceStore.builtInSourceID, valid.id]
        )
    }

    func testBrokenBuiltInFileIsIgnored() throws {
        let context = try makeContext()
        try Data("garbage".utf8).write(to: context.builtInURL)

        XCTAssertTrue(context.store.loadSources().isEmpty)
    }

    func testObservanceVisibilityDefaultsToHiddenAndPersists() throws {
        let context = try makeContext()
        XCTAssertFalse(context.store.showsObservances())

        context.store.setShowsObservances(true)

        XCTAssertTrue(context.makeStore().showsObservances())
    }

    // MARK: - Helpers

    private struct Context {
        let directory: URL
        let builtInURL: URL
        let defaults: UserDefaults
        let hasBuiltIn: Bool
        let store: FileHolidaySourceStore

        func makeStore() -> FileHolidaySourceStore {
            FileHolidaySourceStore(
                builtInURL: hasBuiltIn ? builtInURL : nil,
                directory: directory,
                userDefaults: defaults
            )
        }
    }

    private func makeContext(withBuiltIn: Bool = true) throws -> Context {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VietLunarHolidayTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }

        let builtInURL = root.appendingPathComponent("builtin.ics")
        try Data(sampleCalendar().utf8).write(to: builtInURL)

        let suiteName = "VietLunarTests.Holidays.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }

        let context = Context(
            directory: root.appendingPathComponent("Imported", isDirectory: true),
            builtInURL: builtInURL,
            defaults: defaults,
            hasBuiltIn: withBuiltIn,
            store: FileHolidaySourceStore(
                builtInURL: withBuiltIn ? builtInURL : nil,
                directory: root.appendingPathComponent("Imported", isDirectory: true),
                userDefaults: defaults
            )
        )
        return context
    }

    private func sampleCalendar(name: String? = nil) -> String {
        var lines = ["BEGIN:VCALENDAR", "VERSION:2.0"]
        if let name {
            lines.append("X-WR-CALNAME:\(name)")
        }
        lines += [
            "BEGIN:VEVENT",
            "SUMMARY:Ngày lễ",
            "DTSTART;VALUE=DATE:20260101",
            "END:VEVENT",
            "END:VCALENDAR",
            ""
        ]
        return lines.joined(separator: "\r\n")
    }
}
