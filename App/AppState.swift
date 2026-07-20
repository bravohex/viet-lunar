import Combine
import Foundation
import VietLunarCore

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var currentSnapshot: CalendarSnapshot?
    @Published var titleFormat: MenuBarTitleFormat = .defaultValue
    @Published private(set) var errorMessage: String?

    private let snapshotFactory: CalendarSnapshotFactory

    init(
        snapshotFactory: CalendarSnapshotFactory = CalendarSnapshotFactory(
            lunarEngine: LunarCalendarEngine(),
            clock: SystemClock()
        )
    ) {
        self.snapshotFactory = snapshotFactory
        refresh()
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
            currentSnapshot = try snapshotFactory.makeSnapshot()
            errorMessage = nil
        } catch {
            errorMessage = "Không thể cập nhật lịch âm trong dải ngày được hỗ trợ."
        }
    }
}
