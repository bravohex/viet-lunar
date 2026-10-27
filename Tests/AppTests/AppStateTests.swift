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
        login: TestLoginService = TestLoginService()
    ) -> AppState {
        AppState(lunarEngine: engine, clock: clock, lifecycleSource: TestLifecycle(),
                 boundaryScheduler: scheduler, preferencesStore: TestPreferences(), loginItemService: login)
    }
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
