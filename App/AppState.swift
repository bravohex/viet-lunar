import Combine
import Foundation
import VietLunarCore
import VietLunarInfrastructure

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var currentSnapshot: CalendarSnapshot?
    @Published var titleFormat: MenuBarTitleFormat = .defaultValue
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedSolarDate: SolarDate?
    @Published private(set) var visibleMonth: YearMonth?
    @Published private(set) var monthCells: [MonthGridCell] = []
    @Published private(set) var canNavigateToPreviousMonth = false
    @Published private(set) var canNavigateToNextMonth = false

    private let snapshotFactory: CalendarSnapshotFactory
    private let monthGridBuilder: MonthGridBuilder
    private let lifecycleSource: any LifecycleEventSourcing
    private let boundaryCalculator: any BoundaryCalculating
    private let boundaryScheduler: any BoundaryScheduling
    private var lifecycleCoordinator: LifecycleEventCoordinator?

    init(
        lunarEngine: any LunarCalendarCalculating = LunarCalendarEngine(),
        clock: any Clock = SystemClock(),
        lifecycleSource: any LifecycleEventSourcing = SystemLifecycleSource(),
        boundaryCalculator: any BoundaryCalculating = BoundaryCalculator(),
        boundaryScheduler: (any BoundaryScheduling)? = nil
    ) {
        snapshotFactory = CalendarSnapshotFactory(
            lunarEngine: lunarEngine,
            clock: clock
        )
        monthGridBuilder = MonthGridBuilder(lunarEngine: lunarEngine)
        self.lifecycleSource = lifecycleSource
        self.boundaryCalculator = boundaryCalculator
        self.boundaryScheduler = boundaryScheduler
            ?? OneShotBoundaryScheduler(clock: clock)
        refresh()

        let coordinator = LifecycleEventCoordinator(
            source: lifecycleSource
        ) { [weak self] in
            self?.refresh()
        }
        lifecycleCoordinator = coordinator
        coordinator.start()
    }

    var menuBarPresentation: MenuBarTitlePresentation {
        guard let currentSnapshot else {
            return MenuBarTitlePresentation(
                title: "ÂL",
                accessibilityLabel: "VietLunar — không thể tải ngày âm lịch"
            )
        }

        return VietnameseCalendarFormatter.menuBarPresentation(
            for: currentSnapshot,
            format: titleFormat
        )
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
            try rebuildVisibleMonth()
            errorMessage = nil
            scheduleNextBoundary(after: snapshot.instant)
        } catch {
            errorMessage = "Không thể cập nhật lịch âm trong dải ngày được hỗ trợ."
        }
    }

    func popoverOpened() {
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
                weekStart: .defaultValue,
                today: snapshot.solarDate
            )
            visibleMonth = targetMonth
            self.selectedSolarDate = targetDate
            updateNavigationAvailability()
            errorMessage = nil
        } catch {
            errorMessage = "Ngày này nằm ngoài dải lịch được hỗ trợ."
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
                weekStart: .defaultValue,
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
            errorMessage = "Tháng này nằm ngoài dải lịch được hỗ trợ."
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
            errorMessage = "Không thể mở tháng hiện tại."
        }
    }

    private func rebuildVisibleMonth() throws {
        guard let visibleMonth, let snapshot = currentSnapshot else {
            return
        }

        monthCells = try monthGridBuilder.build(
            displayedMonth: visibleMonth,
            weekStart: .defaultValue,
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
            weekStart: .defaultValue,
            today: snapshot.solarDate
        )) != nil
    }

    private func scheduleNextBoundary(after instant: Date) {
        do {
            let boundary = try boundaryCalculator.nextBoundary(
                after: instant,
                requirements: .lunarDateOnly
            )
            boundaryScheduler.schedule(at: boundary, tolerance: 1) { [weak self] in
                self?.lifecycleSource.emit(.scheduledBoundary)
            }
        } catch {
            boundaryScheduler.cancel()
            errorMessage = "Không thể lên lịch cập nhật ngày tiếp theo."
        }
    }
}
