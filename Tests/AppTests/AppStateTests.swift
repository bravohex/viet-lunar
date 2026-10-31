import Foundation
import VietLunarCore
import VietLunarInfrastructure
import XCTest

final class AppStateTests: XCTestCase {
    @MainActor
    func testTemporaryAppCanDisableButCannotReenableLoginItem() {
        let login = TestLoginService()
        login.requiresInstallation = true
        login.currentStatus = .enabled
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"), login: login)
        state.settingsAppeared()
        XCTAssertTrue(state.canChangeLoginItem)
        state.setLoginItemEnabled(false)
        XCTAssertEqual(state.loginItemStatus, .disabled)
        XCTAssertFalse(state.canChangeLoginItem)
    }
    @MainActor
    func testFailedUnregisterKeepsActualEnabledState() {
        let login = TestLoginService()
        login.currentStatus = .enabled
        login.failure = NSError(domain: "LoginTest", code: 1)
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"), login: login)
        state.settingsAppeared()
        state.setLoginItemEnabled(false)
        XCTAssertEqual(state.loginItemStatus, .enabled)
    }

    @MainActor
    func testSettingsRefreshReadsExternalLoginItemChanges() {
        let login = TestLoginService()
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"), login: login)
        state.settingsAppeared()
        XCTAssertEqual(state.loginItemStatus, .disabled)
        login.currentStatus = .requiresUserApproval
        state.settingsDisappeared()
        state.settingsAppeared()
        XCTAssertEqual(state.loginItemStatus, .requiresUserApproval)
    }

    @MainActor
    func testBoundaryMonthsRemainNavigable() throws {
        for (instant, previous, next, leading) in [
            ("1800-01-01T05:00:00Z", false, true, 2),
            ("2199-12-01T05:00:00Z", true, false, 0)
        ] {
            let state = makeState(clock: TestClock(instant))
            state.popoverOpened()
            XCTAssertEqual(state.monthCells.filter(\.isInDisplayedMonth).count, 31)
            XCTAssertEqual(state.canNavigateToPreviousMonth, previous)
            XCTAssertEqual(state.canNavigateToNextMonth, next)
            XCTAssertEqual(state.leadingGridPlaceholderCount, leading)
            XCTAssertNil(state.errorMessage)
            state.navigateMonth(by: next ? 1 : -1)
            XCTAssertFalse(state.monthCells.isEmpty)
            XCTAssertNil(state.errorMessage)
        }
    }

    @MainActor
    func testShowingTodayFollowsSelectionAndVisibleMonth() {
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"))
        state.popoverOpened()
        XCTAssertTrue(state.isShowingToday)

        state.navigateMonth(by: 1)
        XCTAssertFalse(state.isShowingToday)

        state.returnToToday()
        XCTAssertTrue(state.isShowingToday)

        state.moveSelection(byDays: 1)
        XCTAssertFalse(state.isShowingToday)
    }

    @MainActor
    func testShowingTodayIsFalseAfterDayBoundaryLeavesSelectionBehind() {
        let clock = TestClock("2026-10-26T05:00:00Z")
        let state = makeState(clock: clock)
        state.popoverOpened()
        XCTAssertTrue(state.isShowingToday)

        clock.instant = clock.instant.addingTimeInterval(86_400)
        state.refresh()
        XCTAssertFalse(state.isShowingToday)

        state.returnToToday()
        XCTAssertTrue(state.isShowingToday)
    }

    @MainActor
    func testGridFailureDoesNotStopLiveSnapshotMenuOrScheduler() throws {
        let clock = TestClock("2026-10-26T05:00:00Z")
        let scheduler = TestScheduler()
        let engine = TestEngine()
        let state = makeState(clock: clock, scheduler: scheduler, engine: engine)
        state.popoverOpened()
        engine.failingDate = try SolarDate(validatingYear: 2026, month: 10, day: 1)
        var callbacks = 0
        state.menuBarPresentationDidChange = { callbacks += 1 }
        let scheduled = scheduler.dates.count
        clock.instant = clock.instant.addingTimeInterval(3_600)
        state.refresh()
        XCTAssertEqual(state.currentSnapshot?.instant, clock.instant)
        XCTAssertEqual(callbacks, 1)
        XCTAssertEqual(scheduler.dates.count, scheduled + 1)
        XCTAssertNotNil(state.errorMessage)
        XCTAssertTrue(state.canNavigateToNextMonth)
    }

    @MainActor
    func makeState(
        clock: TestClock,
        scheduler: TestScheduler = TestScheduler(),
        engine: TestEngine = TestEngine(),
        login: TestLoginService = TestLoginService(),
        holidays: TestHolidayStore = TestHolidayStore()
    ) -> AppState {
        AppState(lunarEngine: engine, clock: clock, lifecycleSource: TestLifecycle(),
                 boundaryScheduler: scheduler, preferencesStore: TestPreferences(), loginItemService: login,
                 holidayStore: holidays)
    }

    // MARK: - Holidays

    @MainActor
    func testDefaultHolidaySourceShowsOfficialDaysAndHidesObservances() throws {
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"))
        state.popoverOpened()

        XCTAssertEqual(state.activeHolidaySourceID, FileHolidaySourceStore.builtInSourceID)
        XCTAssertEqual(state.holidays(on: try day(2026, 9, 2)).map(\.name), ["Quốc khánh"])
        XCTAssertTrue(state.holidays(on: try day(2026, 4, 21)).isEmpty)
        XCTAssertTrue(state.holidays(on: try day(2026, 6, 1)).isEmpty)
    }

    @MainActor
    func testObservancesAppearWhenEnabledAndTheChoiceIsStored() throws {
        let holidays = TestHolidayStore()
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"), holidays: holidays)
        state.popoverOpened()

        state.setShowsHolidayObservances(true)

        XCTAssertEqual(state.holidays(on: try day(2026, 4, 21)).map(\.name), ["Ngày Sách"])
        XCTAssertTrue(holidays.observances)

        state.setShowsHolidayObservances(false)
        XCTAssertTrue(state.holidays(on: try day(2026, 4, 21)).isEmpty)
    }

    @MainActor
    func testMultiDayHolidayReportsPositionInsideTheEvent() throws {
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"))
        state.popoverOpened()

        XCTAssertEqual(
            state.holidays(on: try day(2026, 2, 18)),
            [HolidayOccurrence(name: "Tết", kind: .official, dayNumber: 2, dayCount: 3)]
        )
    }

    @MainActor
    func testChoosingNoSourceHidesEveryHolidayAndUnknownSourcesAreIgnored() throws {
        let holidays = TestHolidayStore()
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"), holidays: holidays)
        state.popoverOpened()

        state.selectHolidaySource(nil)
        XCTAssertNil(state.activeHolidaySourceID)
        XCTAssertNil(holidays.active)
        XCTAssertTrue(state.holidays(on: try day(2026, 9, 2)).isEmpty)

        state.selectHolidaySource("missing")
        XCTAssertNil(state.activeHolidaySourceID)

        state.selectHolidaySource(FileHolidaySourceStore.builtInSourceID)
        XCTAssertEqual(state.holidays(on: try day(2026, 9, 2)).count, 1)
    }

    @MainActor
    func testImportedSourceBecomesTheOnlyVisibleSource() throws {
        let holidays = TestHolidayStore()
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"), holidays: holidays)
        state.popoverOpened()

        state.importHolidayCalendar(data: Data(), suggestedName: "japan.ics")

        XCTAssertNil(state.holidayImportErrorMessage)
        XCTAssertEqual(state.holidaySources.count, 2)
        XCTAssertEqual(state.activeHolidaySourceID, TestHolidayStore.importedID)
        XCTAssertEqual(holidays.active, TestHolidayStore.importedID)
        XCTAssertEqual(state.holidays(on: try day(2026, 5, 3)).map(\.name), ["Golden Week"])
        XCTAssertTrue(state.holidays(on: try day(2026, 9, 2)).isEmpty)
    }

    @MainActor
    func testImportFailureNamesTheFileAndTheReason() {
        let holidays = TestHolidayStore()
        holidays.importError = .invalidCalendar(.noEvents)
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"), holidays: holidays)
        state.popoverOpened()

        state.importHolidayCalendar(data: Data(), suggestedName: "x.ics")

        XCTAssertEqual(
            state.holidayImportErrorMessage,
            "x.ics: Tệp không có ngày lễ trong dải 1800–2199."
        )
        XCTAssertEqual(state.activeHolidaySourceID, FileHolidaySourceStore.builtInSourceID)
        XCTAssertEqual(state.holidaySources.count, 1)
    }

    @MainActor
    func testSeveralFailuresAreReportedTogetherUntilCleared() {
        let holidays = TestHolidayStore()
        holidays.importError = .storageFailure
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"), holidays: holidays)
        state.popoverOpened()

        state.importHolidayCalendar(data: Data(), suggestedName: "a.ics")
        state.reportHolidayImportFailure(.tooLarge, fileName: "b.ics")

        XCTAssertEqual(
            state.holidayImportErrorMessage,
            "a.ics: Không thể lưu tệp ngày lễ. Vui lòng thử lại.\nb.ics: Tệp quá lớn (tối đa 1 MB)."
        )

        state.clearHolidayImportError()
        XCTAssertNil(state.holidayImportErrorMessage)
    }

    @MainActor
    func testRemovingTheActiveImportedSourceFallsBackToTheDefault() throws {
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"))
        state.popoverOpened()
        state.importHolidayCalendar(data: Data(), suggestedName: "japan.ics")

        state.removeHolidaySource(TestHolidayStore.importedID)

        XCTAssertEqual(state.holidaySources.map(\.id), [FileHolidaySourceStore.builtInSourceID])
        XCTAssertEqual(state.activeHolidaySourceID, FileHolidaySourceStore.builtInSourceID)
        XCTAssertEqual(state.holidays(on: try day(2026, 9, 2)).count, 1)
    }

    @MainActor
    func testBuiltInSourceCannotBeRemoved() {
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"))
        state.popoverOpened()

        state.removeHolidaySource(FileHolidaySourceStore.builtInSourceID)

        XCTAssertEqual(state.holidaySources.map(\.id), [FileHolidaySourceStore.builtInSourceID])
    }

    @MainActor
    func testStoredSelectionOfAMissingSourceShowsNothing() throws {
        let holidays = TestHolidayStore()
        holidays.active = "deleted-elsewhere"
        let state = makeState(clock: TestClock("2026-10-26T05:00:00Z"), holidays: holidays)
        state.popoverOpened()

        XCTAssertNil(state.activeHolidaySourceID)
        XCTAssertTrue(state.holidays(on: try day(2026, 9, 2)).isEmpty)
    }

    @MainActor
    func testHolidaysAreNotLoadedUntilNeeded() {
        let holidays = TestHolidayStore()
        _ = makeState(clock: TestClock("2026-10-26T05:00:00Z"), holidays: holidays)

        XCTAssertEqual(holidays.loadCount, 0)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> SolarDate {
        try SolarDate(validatingYear: year, month: month, day: day)
    }
}

final class TestHolidayStore: HolidaySourceStoring, @unchecked Sendable {
    static let importedID = "imported"

    var sources: [HolidaySource]
    var active: String? = FileHolidaySourceStore.builtInSourceID
    var observances = false
    var importError: HolidaySourceStoreError?
    private(set) var loadCount = 0

    init() {
        func date(_ year: Int, _ month: Int, _ day: Int) -> SolarDate {
            SolarDate.valid(year: year, month: month, day: day)!
        }
        sources = [
            HolidaySource(
                id: FileHolidaySourceStore.builtInSourceID,
                name: "",
                isBuiltIn: true,
                calendar: HolidayCalendar(name: nil, events: [
                    HolidayEvent(name: "Tết", kind: .official, firstDate: date(2026, 2, 17), dayCount: 3),
                    HolidayEvent(name: "Ngày Sách", kind: .observance, firstDate: date(2026, 4, 21)),
                    HolidayEvent(name: "Quốc khánh", kind: .official, firstDate: date(2026, 9, 2))
                ])
            )
        ]
    }

    func loadSources() -> [HolidaySource] {
        loadCount += 1
        return sources
    }

    func importSource(data: Data, suggestedName: String) throws -> HolidaySource {
        if let importError { throw importError }
        let source = HolidaySource(
            id: Self.importedID,
            name: suggestedName,
            isBuiltIn: false,
            calendar: HolidayCalendar(name: nil, events: [
                HolidayEvent(
                    name: "Golden Week",
                    kind: .official,
                    firstDate: SolarDate.valid(year: 2026, month: 5, day: 3)!
                )
            ])
        )
        sources.append(source)
        return source
    }

    func removeSource(id: String) throws {
        sources.removeAll { $0.id == id && !$0.isBuiltIn }
        if active == id {
            active = FileHolidaySourceStore.builtInSourceID
        }
    }

    func activeSourceID() -> String? { active }
    func setActiveSourceID(_ id: String?) { active = id }
    func showsObservances() -> Bool { observances }
    func setShowsObservances(_ value: Bool) { observances = value }
}

final class TestClock: Clock, @unchecked Sendable {
    var instant: Date
    init(_ iso: String) { instant = ISO8601DateFormatter().date(from: iso)! }
    func now() -> Date { instant }
}

@MainActor final class TestScheduler: BoundaryScheduling {
    var hasScheduledBoundary = false
    var dates: [Date] = []
    func schedule(at boundary: Date, tolerance: TimeInterval, action: @escaping @MainActor @Sendable () -> Void) {
        dates.append(boundary)
        hasScheduledBoundary = true
    }
    func cancel() { hasScheduledBoundary = false }
}

struct TestLifecycle: LifecycleEventSourcing {
    func events() -> AsyncStream<AppLifecycleEvent> { AsyncStream { $0.finish() } }
    func emit(_ event: AppLifecycleEvent) {}
}

struct TestPreferences: PreferencesStoring {
    func load() -> AppPreferences { .defaultValue }
    func save(_ preferences: AppPreferences) throws {}
    func changes() -> AsyncStream<AppPreferences> { AsyncStream { $0.finish() } }
}

final class TestLoginService: LoginItemServicing, @unchecked Sendable {
    var requiresInstallation = false
    var currentStatus: LoginItemStatus = .disabled
    var failure: Error?
    func status() -> LoginItemStatus { currentStatus }
    func setEnabled(_ enabled: Bool) throws {
        if let failure { throw failure }
        currentStatus = enabled ? .enabled : .disabled
    }
    func openSystemSettings() {}
}

final class TestEngine: LunarCalendarCalculating, @unchecked Sendable {
    let base = LunarCalendarEngine()
    var failingDate: SolarDate?
    var supportedSolarRange: ClosedRange<SolarDate> { base.supportedSolarRange }
    func lunarDate(for date: SolarDate) throws -> LunarDate {
        if date == failingDate { throw LunarCalendarError.unsupportedSolarDate(date) }
        return try base.lunarDate(for: date)
    }
    func solarDate(for date: LunarDate) throws -> SolarDate { try base.solarDate(for: date) }
    func monthLength(year: Int, month: Int, isLeapMonth: Bool) throws -> Int {
        try base.monthLength(year: year, month: month, isLeapMonth: isLeapMonth)
    }
    func leapMonth(inLunarYear year: Int) throws -> Int? { try base.leapMonth(inLunarYear: year) }
}
