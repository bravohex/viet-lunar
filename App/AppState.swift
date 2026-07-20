import Combine
import Foundation
import VietLunarCore
import VietLunarInfrastructure

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var currentSnapshot: CalendarSnapshot?
    @Published private(set) var preferences: AppPreferences
    @Published private(set) var loginItemStatus: LoginItemStatus
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedSolarDate: SolarDate?
    @Published private(set) var visibleMonth: YearMonth?
    @Published private(set) var monthCells: [MonthGridCell] = []
    @Published private(set) var canNavigateToPreviousMonth = false
    @Published private(set) var canNavigateToNextMonth = false

    private var snapshotFactory: CalendarSnapshotFactory
    private let monthGridBuilder: MonthGridBuilder
    private let lunarEngine: any LunarCalendarCalculating
    private let clock: any Clock
    private let preferencesStore: any PreferencesStoring
    private let loginItemService: any LoginItemServicing
    private let lifecycleSource: any LifecycleEventSourcing
    private let boundaryCalculator: any BoundaryCalculating
    private let boundaryScheduler: any BoundaryScheduling
    private var lifecycleCoordinator: LifecycleEventCoordinator?
    private var preferencesTask: Task<Void, Never>?
    private var isCalendarPrepared = false
    private var isSettingsVisible = false

    init(
        lunarEngine: any LunarCalendarCalculating = LunarCalendarEngine(),
        clock: any Clock = SystemClock(),
        lifecycleSource: any LifecycleEventSourcing = SystemLifecycleSource(),
        boundaryCalculator: any BoundaryCalculating = BoundaryCalculator(),
        boundaryScheduler: (any BoundaryScheduling)? = nil,
        preferencesStore: any PreferencesStoring = UserDefaultsPreferencesStore(),
        loginItemService: any LoginItemServicing = SMLoginItemService()
    ) {
        let initialPreferences = preferencesStore.load()
        preferences = initialPreferences
        loginItemStatus = .unavailable
        snapshotFactory = CalendarSnapshotFactory(
            lunarEngine: lunarEngine,
            clock: clock,
            boundaryPolicy: initialPreferences.canChiBoundaryPolicy
        )
        monthGridBuilder = MonthGridBuilder(lunarEngine: lunarEngine)
        self.lunarEngine = lunarEngine
        self.clock = clock
        self.preferencesStore = preferencesStore
        self.loginItemService = loginItemService
        self.lifecycleSource = lifecycleSource
        self.boundaryCalculator = boundaryCalculator
        self.boundaryScheduler = boundaryScheduler
            ?? OneShotBoundaryScheduler(clock: clock)
        refresh()

        let coordinator = LifecycleEventCoordinator(
            source: lifecycleSource
        ) { [weak self] in
            self?.refresh()
            if self?.isSettingsVisible == true {
                self?.refreshLoginItemStatus()
            }
        }
        lifecycleCoordinator = coordinator
        coordinator.start()
        observePreferences()
    }

    var menuBarPresentation: MenuBarTitlePresentation {
        guard let currentSnapshot else {
            return MenuBarTitlePresentation(
                title: AppLocalization.text(
                    "common.lunar_abbreviation",
                    fallback: "ÂL"
                ),
                accessibilityLabel: AppLocalization.text(
                    "error.lunar_load.accessibility",
                    fallback: "VietLunar — không thể tải ngày âm lịch"
                )
            )
        }

        let clockText = preferences.showsClock
            ? VietnameseCalendarFormatter.systemClockText(
                at: currentSnapshot.instant,
                timeZone: .autoupdatingCurrent,
                uses24HourClock: preferences.uses24HourClock
            )
            : nil
        return VietnameseCalendarFormatter.menuBarPresentation(
            for: currentSnapshot,
            format: preferences.titleFormat,
            clockText: clockText
        )
    }

    func updatePreferences(_ mutate: (inout AppPreferences) -> Void) {
        var updated = preferences
        mutate(&updated)
        guard updated != preferences else {
            return
        }

        do {
            try preferencesStore.save(updated)
            applyPreferences(updated)
        } catch {
            errorMessage = AppLocalization.text(
                "error.preferences_save",
                fallback: "Không thể lưu cài đặt. Vui lòng thử lại."
            )
        }
    }

    func settingsAppeared() {
        isSettingsVisible = true
        refreshLoginItemStatus()
    }

    func settingsDisappeared() {
        isSettingsVisible = false
    }

    func setLoginItemEnabled(_ isEnabled: Bool) {
        do {
            try loginItemService.setEnabled(isEnabled)
            refreshLoginItemStatus()
        } catch {
            loginItemStatus = .error(
                AppLocalization.format(
                    "error.login_item",
                    fallback: "Không thể thay đổi mục mở khi đăng nhập: %@",
                    error.localizedDescription
                )
            )
        }
    }

    func openLoginItemsSettings() {
        loginItemService.openSystemSettings()
    }

    func refresh() {
        do {
            let snapshot = try snapshotFactory.makeSnapshot()
            currentSnapshot = snapshot
            if selectedSolarDate == nil {
                selectedSolarDate = snapshot.solarDate
            }
            if visibleMonth == nil {
                visibleMonth = try YearMonth(
                    validatingYear: snapshot.solarDate.year,
                    month: snapshot.solarDate.month
                )
            }
            if isCalendarPrepared {
                try rebuildVisibleMonth()
            }
            errorMessage = nil
            scheduleNextBoundary(after: snapshot.instant)
        } catch {
            errorMessage = AppLocalization.text(
                "error.calendar_refresh",
                fallback: "Không thể cập nhật lịch âm trong dải ngày được hỗ trợ."
            )
        }
    }

    func popoverOpened() {
        if !isCalendarPrepared {
            isCalendarPrepared = true
            do {
                try rebuildVisibleMonth()
                errorMessage = nil
            } catch {
                errorMessage = AppLocalization.text(
                    "error.calendar_refresh",
                    fallback: "Không thể cập nhật lịch âm trong dải ngày được hỗ trợ."
                )
            }
        }
        lifecycleSource.emit(.popoverOpened)
    }

    var selectedCell: MonthGridCell? {
        guard let selectedSolarDate else {
            return nil
        }
        return monthCells.first { $0.solarDate == selectedSolarDate }
    }

    func select(_ solarDate: SolarDate) {
        selectedSolarDate = solarDate
    }

    func moveSelection(byDays offset: Int) {
        guard let selectedSolarDate,
              let snapshot = currentSnapshot,
              let targetDate = try? GregorianJDN.solarDate(
                  forJDN: GregorianJDN.jdn(for: selectedSolarDate) + offset
              ),
              let targetMonth = YearMonth.valid(
                  year: targetDate.year,
                  month: targetDate.month
              )
        else {
            return
        }

        if monthCells.contains(where: { $0.solarDate == targetDate }) {
            self.selectedSolarDate = targetDate
            return
        }

        do {
            monthCells = try monthGridBuilder.build(
                displayedMonth: targetMonth,
                weekStart: preferences.weekStart,
                today: snapshot.solarDate
            )
            visibleMonth = targetMonth
            self.selectedSolarDate = targetDate
            updateNavigationAvailability()
            errorMessage = nil
        } catch {
            errorMessage = AppLocalization.text(
                "error.date_out_of_range",
                fallback: "Ngày này nằm ngoài dải lịch được hỗ trợ."
            )
        }
    }

    func navigateMonth(by offset: Int) {
        guard let visibleMonth,
              let targetMonth = try? visibleMonth.adding(months: offset),
              let snapshot = currentSnapshot
        else {
            return
        }

        do {
            let cells = try monthGridBuilder.build(
                displayedMonth: targetMonth,
                weekStart: preferences.weekStart,
                today: snapshot.solarDate
            )
            self.visibleMonth = targetMonth
            monthCells = cells

            let preferredDay = selectedSolarDate?.day ?? 1
            let maximumDay = SolarDate.daysInMonth(
                year: targetMonth.year,
                month: targetMonth.month
            ) ?? 1
            selectedSolarDate = SolarDate.valid(
                year: targetMonth.year,
                month: targetMonth.month,
                day: min(preferredDay, maximumDay)
            )
            updateNavigationAvailability()
            errorMessage = nil
        } catch {
            errorMessage = AppLocalization.text(
                "error.month_out_of_range",
                fallback: "Tháng này nằm ngoài dải lịch được hỗ trợ."
            )
        }
    }

    func returnToToday() {
        guard let snapshot = currentSnapshot,
              let month = YearMonth.valid(
                  year: snapshot.solarDate.year,
                  month: snapshot.solarDate.month
              )
        else {
            return
        }

        selectedSolarDate = snapshot.solarDate
        visibleMonth = month
        do {
            try rebuildVisibleMonth()
            errorMessage = nil
        } catch {
            errorMessage = AppLocalization.text(
                "error.current_month",
                fallback: "Không thể mở tháng hiện tại."
            )
        }
    }

    private func rebuildVisibleMonth() throws {
        guard let visibleMonth, let snapshot = currentSnapshot else {
            return
        }

        monthCells = try monthGridBuilder.build(
            displayedMonth: visibleMonth,
            weekStart: preferences.weekStart,
            today: snapshot.solarDate
        )
        updateNavigationAvailability()
    }

    private func updateNavigationAvailability() {
        canNavigateToPreviousMonth = canBuildMonth(offset: -1)
        canNavigateToNextMonth = canBuildMonth(offset: 1)
    }

    private func canBuildMonth(offset: Int) -> Bool {
        guard let visibleMonth,
              let snapshot = currentSnapshot,
              let target = try? visibleMonth.adding(months: offset)
        else {
            return false
        }

        return (try? monthGridBuilder.build(
            displayedMonth: target,
            weekStart: preferences.weekStart,
            today: snapshot.solarDate
        )) != nil
    }

    private func scheduleNextBoundary(after instant: Date) {
        do {
            let boundary = try boundaryCalculator.nextBoundary(
                after: instant,
                requirements: preferences.refreshRequirements(
                    displayedClockTimeZone: .autoupdatingCurrent
                )
            )
            boundaryScheduler.schedule(at: boundary, tolerance: 1) { [weak self] in
                self?.lifecycleSource.emit(.scheduledBoundary)
            }
        } catch {
            boundaryScheduler.cancel()
            errorMessage = AppLocalization.text(
                "error.refresh_schedule",
                fallback: "Không thể lên lịch cập nhật ngày tiếp theo."
            )
        }
    }

    private func observePreferences() {
        let changes = preferencesStore.changes()
        preferencesTask = Task { [weak self] in
            for await preferences in changes {
                guard !Task.isCancelled, let self else {
                    return
                }
                applyPreferences(preferences)
            }
        }
    }

    private func refreshLoginItemStatus() {
        loginItemStatus = loginItemService.status()
    }

    private func applyPreferences(_ newPreferences: AppPreferences) {
        guard newPreferences != preferences else {
            return
        }
        preferences = newPreferences
        snapshotFactory = CalendarSnapshotFactory(
            lunarEngine: lunarEngine,
            clock: clock,
            boundaryPolicy: newPreferences.canChiBoundaryPolicy
        )
        refresh()
    }
}
