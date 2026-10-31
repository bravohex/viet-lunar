import Combine
import Foundation
import VietLunarCore
import VietLunarInfrastructure

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var currentSnapshot: CalendarSnapshot?
    @Published private(set) var preferences: AppPreferences
    @Published private(set) var loginItemStatus: LoginItemStatus
    @Published private(set) var loginItemErrorMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedSolarDate: SolarDate?
    @Published private(set) var visibleMonth: YearMonth?
    @Published private(set) var monthCells: [MonthGridCell] = []
    @Published private(set) var canNavigateToPreviousMonth = false
    @Published private(set) var canNavigateToNextMonth = false
    @Published private(set) var holidaySources: [HolidaySource] = []
    @Published private(set) var activeHolidaySourceID: String?
    @Published private(set) var showsHolidayObservances = false
    @Published private(set) var holidayImportErrorMessage: String?
    @Published private(set) var holidayIndex = HolidayIndex.empty

    private var snapshotFactory: CalendarSnapshotFactory
    private let monthGridBuilder: MonthGridBuilder
    private let lunarEngine: any LunarCalendarCalculating
    private let clock: any Clock
    private let preferencesStore: any PreferencesStoring
    private let loginItemService: any LoginItemServicing
    private let lifecycleSource: any LifecycleEventSourcing
    private let boundaryCalculator: any BoundaryCalculating
    private let boundaryScheduler: any BoundaryScheduling
    private let holidayStore: any HolidaySourceStoring
    private var lifecycleCoordinator: LifecycleEventCoordinator?
    private var preferencesTask: Task<Void, Never>?
    private var isCalendarPrepared = false
    private var isSettingsVisible = false
    private var areHolidaysLoaded = false

    var menuBarPresentationDidChange: (() -> Void)?

    init(
        lunarEngine: any LunarCalendarCalculating = LunarCalendarEngine(),
        clock: any Clock = SystemClock(),
        lifecycleSource: any LifecycleEventSourcing = SystemLifecycleSource(),
        boundaryCalculator: any BoundaryCalculating = BoundaryCalculator(),
        boundaryScheduler: (any BoundaryScheduling)? = nil,
        preferencesStore: any PreferencesStoring = UserDefaultsPreferencesStore(),
        loginItemService: any LoginItemServicing = SMLoginItemService(),
        holidayStore: (any HolidaySourceStoring)? = nil
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
        self.holidayStore = holidayStore ?? FileHolidaySourceStore(
            builtInURL: Bundle.main.url(forResource: "vietnam", withExtension: "ics")
        )
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
        loadHolidaysIfNeeded()
        refreshLoginItemStatus()
    }

    func settingsDisappeared() {
        isSettingsVisible = false
    }

    var loginItemRequiresInstallation: Bool { loginItemService.requiresInstallation }

    var canChangeLoginItem: Bool {
        !loginItemRequiresInstallation || loginItemStatus == .enabled
            || loginItemStatus == .requiresUserApproval
    }

    func setLoginItemEnabled(_ isEnabled: Bool) {
        do {
            try loginItemService.setEnabled(isEnabled)
            refreshLoginItemStatus()
            loginItemErrorMessage = nil
        } catch {
            // An unsuccessful unregister does not mean the item is disabled.
            refreshLoginItemStatus()
            loginItemErrorMessage = AppLocalization.format(
                "error.login_item",
                fallback: "Không thể thay đổi mục mở khi đăng nhập: %@",
                error.localizedDescription
            )
        }
    }

    func openLoginItemsSettings() {
        loginItemService.openSystemSettings()
    }

    func refresh() {
        do {
            let snapshot = try makeInstrumentedSnapshot()
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
            errorMessage = nil
            if isCalendarPrepared {
                do {
                    try rebuildVisibleMonth()
                } catch {
                    errorMessage = AppLocalization.text(
                        "error.current_month", fallback: "Không thể mở tháng hiện tại."
                    )
                }
            }
            scheduleNextBoundary(after: snapshot.instant)
            menuBarPresentationDidChange?()
        } catch {
            errorMessage = AppLocalization.text(
                "error.calendar_refresh",
                fallback: "Không thể cập nhật lịch âm trong dải ngày được hỗ trợ."
            )
        }
    }

    func popoverOpened() {
        loadHolidaysIfNeeded()
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

    /// True while today's date is the selected date, which also means today's
    /// month is displayed. The footer uses it to disable "Hôm nay".
    var isShowingToday: Bool {
        guard let currentSnapshot else {
            return false
        }
        return selectedSolarDate == currentSnapshot.solarDate
    }

    var leadingGridPlaceholderCount: Int {
        guard let first = monthCells.first else { return 0 }
        let mondayIndex = GregorianJDN.jdn(for: first.solarDate) % 7
        return preferences.weekStart == .monday ? mondayIndex : (mondayIndex + 1) % 7
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

    // MARK: - Holidays

    /// Holidays shown for `date`: official ones always, observances only when
    /// the user turned them on.
    func holidays(on date: SolarDate) -> [HolidayOccurrence] {
        let occurrences = holidayIndex.occurrences(on: date)
        return showsHolidayObservances
            ? occurrences
            : occurrences.filter { $0.kind == .official }
    }

    /// Only one source is visible at a time; nil shows no holidays.
    func selectHolidaySource(_ id: String?) {
        loadHolidaysIfNeeded()
        if let id, !holidaySources.contains(where: { $0.id == id }) {
            return
        }

        holidayStore.setActiveSourceID(id)
        activeHolidaySourceID = id
        rebuildHolidayIndex()
        holidayImportErrorMessage = nil
    }

    func setShowsHolidayObservances(_ value: Bool) {
        loadHolidaysIfNeeded()
        holidayStore.setShowsObservances(value)
        showsHolidayObservances = value
    }

    func clearHolidayImportError() {
        holidayImportErrorMessage = nil
    }

    /// Imports one file. A successful import becomes the visible source; a
    /// failure is appended to the message so several files can be reported
    /// together (call `clearHolidayImportError()` before a batch).
    func importHolidayCalendar(data: Data, suggestedName: String) {
        loadHolidaysIfNeeded()
        do {
            let source = try holidayStore.importSource(
                data: data,
                suggestedName: suggestedName
            )
            holidaySources = holidayStore.loadSources()
            holidayStore.setActiveSourceID(source.id)
            activeHolidaySourceID = source.id
            rebuildHolidayIndex()
        } catch let error as HolidaySourceStoreError {
            reportHolidayImportMessage(
                holidayMessage(for: error),
                fileName: suggestedName
            )
        } catch {
            reportHolidayImportMessage(
                holidayMessage(for: .storageFailure),
                fileName: suggestedName
            )
        }
    }

    func reportHolidayImportFailure(_ failure: HolidayImportFailure, fileName: String) {
        switch failure {
        case .unreadable:
            reportHolidayImportMessage(
                holidayMessage(for: .invalidCalendar(.notText)),
                fileName: fileName
            )
        case .tooLarge:
            reportHolidayImportMessage(
                holidayMessage(for: .invalidCalendar(.tooLarge)),
                fileName: fileName
            )
        }
    }

    func removeHolidaySource(_ id: String) {
        loadHolidaysIfNeeded()
        guard let source = holidaySources.first(where: { $0.id == id }),
              !source.isBuiltIn
        else {
            return
        }

        do {
            try holidayStore.removeSource(id: id)
            reloadHolidays()
            holidayImportErrorMessage = nil
        } catch {
            holidayImportErrorMessage = holidayMessage(for: .storageFailure)
        }
    }

    private func loadHolidaysIfNeeded() {
        guard !areHolidaysLoaded else {
            return
        }
        areHolidaysLoaded = true
        reloadHolidays()
    }

    private func reloadHolidays() {
        holidaySources = holidayStore.loadSources()
        let storedID = holidayStore.activeSourceID()
        activeHolidaySourceID = holidaySources.contains { $0.id == storedID }
            ? storedID
            : nil
        showsHolidayObservances = holidayStore.showsObservances()
        rebuildHolidayIndex()
    }

    private func rebuildHolidayIndex() {
        if let activeHolidaySourceID,
           let source = holidaySources.first(where: { $0.id == activeHolidaySourceID }) {
            holidayIndex = HolidayIndex(calendar: source.calendar)
        } else {
            holidayIndex = .empty
        }
    }

    private func reportHolidayImportMessage(_ message: String, fileName: String) {
        let line = fileName.isEmpty
            ? message
            : AppLocalization.format(
                "holidays.error.file",
                fallback: "%1$@: %2$@",
                fileName,
                message
            )
        holidayImportErrorMessage = holidayImportErrorMessage.map { $0 + "\n" + line } ?? line
    }

    private func holidayMessage(for error: HolidaySourceStoreError) -> String {
        switch error {
        case .invalidCalendar(.tooLarge):
            AppLocalization.text(
                "holidays.error.too_large",
                fallback: "Tệp quá lớn (tối đa 1 MB)."
            )
        case .invalidCalendar(.tooManyEvents):
            AppLocalization.text(
                "holidays.error.too_many",
                fallback: "Tệp có quá nhiều ngày lễ."
            )
        case .invalidCalendar(.noEvents):
            AppLocalization.text(
                "holidays.error.empty",
                fallback: "Tệp không có ngày lễ trong dải 1800–2199."
            )
        case .invalidCalendar(.notText):
            AppLocalization.text(
                "holidays.error.unreadable",
                fallback: "Không đọc được tệp. Hãy chọn tệp .ics hợp lệ."
            )
        case .storageFailure:
            AppLocalization.text(
                "holidays.error.storage",
                fallback: "Không thể lưu tệp ngày lễ. Vui lòng thử lại."
            )
        }
    }

    private func rebuildVisibleMonth() throws {
        guard let visibleMonth, let snapshot = currentSnapshot else {
            return
        }

        defer { updateNavigationAvailability() }
        monthCells = try monthGridBuilder.build(
            displayedMonth: visibleMonth,
            weekStart: preferences.weekStart,
            today: snapshot.solarDate
        )
    }

    private func makeInstrumentedSnapshot() throws -> CalendarSnapshot {
        let interval = AppPerformance.signposter.beginInterval(
            "Calendar Snapshot"
        )
        defer {
            AppPerformance.signposter.endInterval(
                "Calendar Snapshot",
                interval
            )
        }
        return try snapshotFactory.makeSnapshot()
    }

    private func updateNavigationAvailability() {
        canNavigateToPreviousMonth = canBuildMonth(offset: -1)
        canNavigateToNextMonth = canBuildMonth(offset: 1)
    }

    private func canBuildMonth(offset: Int) -> Bool {
        guard let visibleMonth,
              let target = try? visibleMonth.adding(months: offset),
              let firstDay = SolarDate.valid(year: target.year, month: target.month, day: 1)
        else {
            return false
        }

        return lunarEngine.supportedSolarRange.contains(firstDay)
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

/// Why a chosen holiday file could not even be handed to the importer.
enum HolidayImportFailure {
    case unreadable
    case tooLarge
}
