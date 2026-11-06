import Foundation
import SwiftUI
import UniformTypeIdentifiers
import VietLunarCore

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedPane: SettingsPane = .general
    @State private var isImportingHolidays = false
    @State private var isManagingHolidays = false
    @State private var pendingRemoval: HolidaySource?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                paneButton(
                    title: AppLocalization.text(
                        "settings.tab.general",
                        fallback: "Chung"
                    ),
                    icon: .settings,
                    pane: .general,
                    identifier: "general-tab"
                )
                paneButton(
                    title: AppLocalization.text(
                        "settings.tab.about",
                        fallback: "Giới thiệu"
                    ),
                    icon: .info,
                    pane: .about,
                    identifier: "about-tab"
                )
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            Divider()

            switch selectedPane {
            case .general:
                generalSettings
            case .about:
                AboutSettingsView()
            }
        }
        .frame(width: 540, height: 560)
    }

    private func paneButton(
        title: String,
        icon: IconAsset,
        pane: SettingsPane,
        identifier: String
    ) -> some View {
        let button = Button {
            selectedPane = pane
        } label: {
            Label {
                Text(title)
            } icon: {
                AssetIconView(icon, size: 16)
            }
        }
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(selectedPane == pane ? .isSelected : [])
        return paneStyle(button, isSelected: selectedPane == pane)
    }

    @ViewBuilder
    private func paneStyle(_ button: some View, isSelected: Bool) -> some View {
        if isSelected {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section(
                    AppLocalization.text(
                        "settings.section.menu_bar",
                        fallback: "Thanh menu"
                    )
                ) {
                Picker(
                    AppLocalization.text(
                        "settings.field.content",
                        fallback: "Nội dung"
                    ),
                    selection: titleFormatBinding
                ) {
                    ForEach(MenuBarTitleFormat.allCases, id: \.self) { format in
                        Text(format.vietnameseName).tag(format)
                    }
                }
                .accessibilityIdentifier("title-format-picker")

                Toggle(
                    AppLocalization.text(
                        "settings.toggle.solar_date",
                        fallback: "Hiện ngày dương"
                    ),
                    isOn: solarDateBinding
                )
                    .disabled(appState.preferences.titleFormat.isIconOnly)
                    .accessibilityIdentifier("show-solar-date-toggle")

                Toggle(
                    AppLocalization.text(
                        "settings.toggle.day_can_chi",
                        fallback: "Hiện Can–Chi ngày"
                    ),
                    isOn: dayCanChiBinding
                )
                    .disabled(appState.preferences.titleFormat.isIconOnly)
                    .accessibilityIdentifier("show-day-can-chi-toggle")

                Toggle(
                    AppLocalization.text(
                        "settings.toggle.clock",
                        fallback: "Hiện đồng hồ"
                    ),
                    isOn: clockBinding
                )
                    .accessibilityIdentifier("show-clock-toggle")

                Toggle(
                    AppLocalization.text(
                        "settings.toggle.24_hour",
                        fallback: "Dùng định dạng 24 giờ"
                    ),
                    isOn: uses24HourClockBinding
                )
                    .disabled(!appState.preferences.showsClock)
                    .accessibilityIdentifier("use-24-hour-toggle")

                LabeledContent(
                    AppLocalization.text(
                        "settings.preview",
                        fallback: "Xem trước"
                    )
                ) {
                    Text(menuTitlePreview)
                        .monospacedDigit()
                        .accessibilityIdentifier("menu-title-preview")
                }
            }

                Section(
                    AppLocalization.text(
                        "settings.section.calendar",
                        fallback: "Lịch"
                    )
                ) {
                Picker(
                    AppLocalization.text(
                        "settings.field.week_start",
                        fallback: "Tuần bắt đầu vào"
                    ),
                    selection: weekStartBinding
                ) {
                    ForEach(WeekStart.allCases, id: \.self) { weekStart in
                        Text(weekStart.vietnameseName).tag(weekStart)
                    }
                }
                .accessibilityIdentifier("week-start-picker")

                LabeledContent(
                    AppLocalization.text(
                        "settings.field.can_chi_policy",
                        fallback: "Quy ước Can–Chi"
                    )
                ) {
                    Text(dayBoundaryDescription)
                }
                Text(
                    AppLocalization.text(
                        "settings.calendar_utc7_note",
                        fallback: "Ngày âm và Can–Chi được tính theo lịch Việt Nam UTC+7."
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

                holidaySection

                Section(
                    AppLocalization.text(
                        "settings.section.system",
                        fallback: "Hệ thống"
                    )
                ) {
                Toggle(
                    AppLocalization.text(
                        "settings.toggle.launch_at_login",
                        fallback: "Mở VietLunar khi đăng nhập"
                    ),
                    isOn: loginItemBinding
                )
                    .disabled(!appState.canChangeLoginItem)
                    .accessibilityIdentifier("launch-at-login-toggle")
                if let loginItemStatusMessage {
                    Text(loginItemStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let message = appState.loginItemErrorMessage {
                    ErrorMessageLabel(message, identifier: "login-item-error")
                }

                if appState.loginItemStatus == .requiresUserApproval {
                    Button(
                        AppLocalization.text(
                            "settings.open_system_settings",
                            fallback: "Mở Cài đặt hệ thống"
                        )
                    ) {
                        appState.openLoginItemsSettings()
                    }
                    .accessibilityIdentifier("open-login-items-settings-button")
                }
            }

                if let errorMessage = appState.errorMessage {
                    ErrorMessageLabel(errorMessage, identifier: "settings-error")
                }
            }
            .formStyle(.grouped)
        }
        .fileImporter(
            isPresented: $isImportingHolidays,
            allowedContentTypes: Self.holidayContentTypes,
            allowsMultipleSelection: true
        ) { result in
            importHolidayFiles(result)
        }
        .sheet(isPresented: $isManagingHolidays) { holidayManager }
        .onAppear {
            appState.settingsAppeared()
        }
        .onDisappear {
            appState.settingsDisappeared()
        }
    }

    private var holidaySection: some View {
        Section(
            AppLocalization.text(
                "settings.section.holidays",
                fallback: "Ngày lễ"
            )
        ) {
            Picker(
                AppLocalization.text(
                    "settings.field.holiday_source",
                    fallback: "Nguồn"
                ),
                selection: holidaySourceBinding
            ) {
                Text(
                    AppLocalization.text(
                        "holidays.source.none",
                        fallback: "Không hiện"
                    )
                )
                .tag(String?.none)
                ForEach(appState.holidaySources) { source in
                    Text(holidaySourceName(source)).tag(Optional(source.id))
                }
            }
            .accessibilityIdentifier("holiday-source-picker")

            ForEach(holidayCoverageLines, id: \.self) { line in
                Text(line)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Toggle(
                AppLocalization.text(
                    "settings.toggle.holiday_observances",
                    fallback: "Hiện cả ngày kỷ niệm"
                ),
                isOn: holidayObservancesBinding
            )
            .disabled(appState.activeHolidaySourceID == nil)
            .accessibilityIdentifier("show-holiday-observances-toggle")

            HStack {
                Button(
                    AppLocalization.text(
                        "holidays.import.button",
                        fallback: "Nhập tệp .ics…"
                    )
                ) {
                    isImportingHolidays = true
                }
                .accessibilityIdentifier("import-holidays-button")

                Button(AppLocalization.text("holidays.manage", fallback: "Quản lý tệp ICS…")) {
                    isManagingHolidays = true
                }
                .accessibilityIdentifier("manage-holidays-button")
            }

            if let message = appState.holidayImportErrorMessage {
                ErrorMessageLabel(message, identifier: "holiday-import-error")
            }
        }
    }

    private static var holidayContentTypes: [UTType] {
        [UTType.calendarEvent, UTType(filenameExtension: "ics")].compactMap { $0 }
    }

    private func importHolidayFiles(_ result: Result<[URL], Error>) {
        appState.clearHolidayImportError()
        let urls: [URL]
        switch result {
        case let .success(selected):
            urls = selected
        case let .failure(error):
            if (error as? CocoaError)?.code != .userCancelled {
                appState.reportHolidayImportFailure(.unreadable, fileName: "")
            }
            return
        }

        for url in urls {
            let fileName = url.lastPathComponent
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= ICSHolidayParser.maximumByteCount else {
                    appState.reportHolidayImportFailure(.tooLarge, fileName: fileName)
                    continue
                }
                let data = try Data(contentsOf: url)
                appState.importHolidayCalendar(data: data, suggestedName: fileName)
            } catch {
                appState.reportHolidayImportFailure(.unreadable, fileName: fileName)
            }
        }
    }

    private var activeHolidaySource: HolidaySource? {
        appState.activeHolidaySource
    }

    private var importedHolidaySources: [HolidaySource] {
        appState.holidaySources.filter { !$0.isBuiltIn }
    }

    private var holidayManager: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("holidays.manage.title", fallback: "Tệp ICS đã thêm"))
                .font(.headline)
            Text(AppLocalization.text(
                "holidays.manage.note",
                fallback: "Chỉ xóa bản sao trong VietLunar. Tệp gốc của bạn được giữ nguyên."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)

            if importedHolidaySources.isEmpty {
                Text(AppLocalization.text("holidays.manage.empty", fallback: "Chưa có tệp ICS nào."))
                    .accessibilityIdentifier("imported-holidays-empty")
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(importedHolidaySources) { source in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(source.name).lineLimit(2).help(source.name)
                                    if source.id == appState.activeHolidaySourceID {
                                        Text(AppLocalization.text("holidays.manage.active", fallback: "Đang dùng"))
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button(AppLocalization.text("holidays.remove", fallback: "Xóa")) {
                                    pendingRemoval = source
                                }
                                .accessibilityLabel(AppLocalization.format(
                                    "holidays.remove.named", fallback: "Xóa %@", source.name
                                ))
                                .accessibilityIdentifier("remove-holiday-source-\(source.id)")
                            }
                        }
                    }.padding(4)
                }
                .frame(maxHeight: 240)
            }

            if let message = appState.holidayImportErrorMessage {
                ErrorMessageLabel(message, identifier: "holiday-manager-error")
            }
            HStack {
                Spacer()
                Button(AppLocalization.text("holidays.manage.done", fallback: "Xong")) {
                    isManagingHolidays = false
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("close-holiday-manager-button")
            }
        }
        .padding(24)
        .frame(width: 440)
        .alert(
            AppLocalization.text("holidays.remove.title", fallback: "Xóa lịch ICS?"),
            isPresented: Binding(
                get: { pendingRemoval != nil },
                set: { if !$0 { pendingRemoval = nil } }
            ),
            presenting: pendingRemoval
        ) { source in
            Button(AppLocalization.text("holidays.remove", fallback: "Xóa"), role: .destructive) {
                appState.removeHolidaySource(source.id)
            }
            Button(AppLocalization.text("holidays.remove.cancel", fallback: "Hủy"), role: .cancel) {}
        } message: { source in
            Text(AppLocalization.format(
                "holidays.remove.confirm",
                fallback: "Xóa “%@” khỏi VietLunar? Nếu đang dùng lịch này, ứng dụng sẽ chuyển về lịch Việt Nam mặc định.",
                source.name
            ))
        }
    }

    private func holidaySourceName(_ source: HolidaySource) -> String {
        if source.isBuiltIn && source.name.isEmpty {
            return AppLocalization.text(
                "holidays.source.built_in",
                fallback: "Việt Nam"
            )
        }
        return source.name
    }

    /// Source year bounds and a warning for the year being viewed in the grid.
    private var holidayCoverageLines: [String] {
        guard let range = activeHolidaySource?.calendar.yearRange else {
            return []
        }

        var lines: [String] = []
        if range.lowerBound == range.upperBound {
            lines.append(
                AppLocalization.format(
                    "holidays.coverage.year",
                    fallback: "Có dữ liệu cho năm %@",
                    String(range.lowerBound)
                )
            )
        } else {
            lines.append(
                AppLocalization.format(
                    "holidays.coverage.years",
                    fallback: "Có dữ liệu cho năm %1$@–%2$@",
                    String(range.lowerBound),
                    String(range.upperBound)
                )
            )
        }
        if let warning = appState.holidayCoverageWarning {
            lines.append(warning)
        }
        return lines
    }

    private var holidaySourceBinding: Binding<String?> {
        Binding(
            get: { appState.activeHolidaySourceID },
            set: { appState.selectHolidaySource($0) }
        )
    }

    private var holidayObservancesBinding: Binding<Bool> {
        Binding(
            get: { appState.showsHolidayObservances },
            set: { appState.setShowsHolidayObservances($0) }
        )
    }

    private var titleFormatBinding: Binding<MenuBarTitleFormat> {
        Binding(
            get: { appState.preferences.titleFormat },
            set: { value in
                appState.updatePreferences { $0.titleFormat = value }
            }
        )
    }

    private var solarDateBinding: Binding<Bool> {
        Binding(
            get: { appState.preferences.titleFormat.includesSolarDate },
            set: { value in
                appState.updatePreferences {
                    $0.titleFormat = $0.titleFormat.withSolarDate(value)
                }
            }
        )
    }

    private var dayCanChiBinding: Binding<Bool> {
        Binding(
            get: { appState.preferences.titleFormat.includesDayCanChi },
            set: { value in
                appState.updatePreferences {
                    $0.titleFormat = $0.titleFormat.withDayCanChi(value)
                }
            }
        )
    }

    private var clockBinding: Binding<Bool> {
        Binding(
            get: { appState.preferences.showsClock },
            set: { value in
                appState.updatePreferences { $0.showsClock = value }
            }
        )
    }

    private var uses24HourClockBinding: Binding<Bool> {
        Binding(
            get: { appState.preferences.uses24HourClock },
            set: { value in
                appState.updatePreferences { $0.uses24HourClock = value }
            }
        )
    }

    private var weekStartBinding: Binding<WeekStart> {
        Binding(
            get: { appState.preferences.weekStart },
            set: { value in
                appState.updatePreferences { $0.weekStart = value }
            }
        )
    }

    private var loginItemBinding: Binding<Bool> {
        Binding(
            get: {
                appState.loginItemStatus == .enabled
                    || appState.loginItemStatus == .requiresUserApproval
            },
            set: { value in
                appState.setLoginItemEnabled(value)
            }
        )
    }

    private var menuTitlePreview: String {
        if appState.preferences.titleFormat.isIconOnly {
            return appState.menuBarPresentation.title.map { "☾  \($0)" } ?? "☾"
        }
        return appState.menuBarPresentation.title
            ?? AppLocalization.text(
                "common.lunar_abbreviation",
                fallback: "ÂL"
            )
    }

    private var dayBoundaryDescription: String {
        switch appState.preferences.canChiBoundaryPolicy {
        case .civilMidnight:
            AppLocalization.text(
                "settings.boundary.civil_midnight",
                fallback: "Đổi ngày lúc 00:00"
            )
        case .startOfZiHour:
            AppLocalization.text(
                "settings.boundary.zi_hour",
                fallback: "Đổi ngày lúc 23:00"
            )
        }
    }

    /// Only states that need the user to act or understand something get a
    /// message. "enabled" and "disabled" are already shown by the toggle, and
    /// an enabled registration is not proof that macOS will relaunch the app.
    private var loginItemStatusMessage: String? {
        if appState.loginItemRequiresInstallation {
            return AppLocalization.text(
                "settings.login_item.requires_installation",
                fallback: "Hãy chuyển VietLunar vào Applications, mở bản đã cài rồi bật lại tùy chọn này."
            )
        }
        switch appState.loginItemStatus {
        case .disabled, .enabled:
            return nil
        case .requiresUserApproval:
            return AppLocalization.text(
                "settings.login_item.requires_approval",
                fallback: "macOS cần bạn cho phép VietLunar trong Cài đặt hệ thống > Mục đăng nhập."
            )
        case .unavailable:
            return AppLocalization.text(
                "settings.login_item.unavailable",
                fallback: "Chưa tìm thấy đăng ký mở khi đăng nhập. Hãy mở bản đã cài trong Applications và bật lại."
            )
        case let .error(message):
            return message
        }
    }
}

private enum SettingsPane {
    case general
    case about
}

private struct AboutSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(verbatim: "VietLunar")
                    .font(.title.bold())
                Text(
                    AppLocalization.format(
                        "about.version_build",
                        fallback: "Phiên bản %1$@ (%2$@)",
                        version,
                        build
                    )
                )
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("about-version")

                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        AppLocalization.format(
                            "about.author",
                            fallback: "Tác giả: %@",
                            author
                        )
                    )
                        .accessibilityIdentifier("about-author")
                    Text(
                        AppLocalization.format(
                            "about.copyright",
                            fallback: "Copyright © %1$@ %2$@",
                            copyrightYear,
                            author
                        )
                    )
                        .accessibilityIdentifier("about-copyright")
                    Text(
                        AppLocalization.text(
                            "about.license",
                            fallback: "Giấy phép MIT"
                        )
                    )
                        .accessibilityIdentifier("about-license")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                GroupBox(
                    AppLocalization.text(
                        "about.section.scope",
                        fallback: "Phạm vi và quy ước"
                    )
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(
                            AppLocalization.text(
                                "about.supported_range",
                                fallback: "Hỗ trợ ngày dương từ 01/01/1800 đến 31/12/2199. Lịch âm Việt Nam và Can–Chi dùng quy ước UTC+7."
                            )
                        )
                        Text(
                            AppLocalization.text(
                                "about.historical_caveat",
                                fallback: "Kết quả từ 1800 đến 1975 là lịch Việt Nam hiện đại suy rộng, không phải bản phục dựng lịch chính thức của mọi vùng và thời kỳ lịch sử."
                            )
                        )
                            .accessibilityIdentifier("historical-caveat")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox(
                    AppLocalization.text(
                        "about.section.privacy",
                        fallback: "Quyền riêng tư"
                    )
                ) {
                    Text(
                        AppLocalization.text(
                            "about.privacy_summary",
                            fallback: "Ứng dụng chạy offline, không yêu cầu tài khoản và không gửi dữ liệu cá nhân ra ngoài máy Mac."
                        )
                    )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("privacy-summary")
                }

                GroupBox(
                    AppLocalization.text(
                        "about.section.sources",
                        fallback: "Nguồn đối chiếu"
                    )
                ) {
                    Text(
                        AppLocalization.text(
                            "about.sources_summary",
                            fallback: "Quy tắc và kết quả được đối chiếu với tài liệu của Hồ Ngọc Đức, Calendrical Calculations (Edward M. Reingold và Nachum Dershowitz), cùng Hermetic Systems. Không nhúng mã nguồn của các tài liệu này."
                        )
                    )
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(
                    AppLocalization.text(
                        "about.runtime_summary",
                        fallback: "Chỉ sử dụng Apple platform frameworks ở runtime."
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .accessibilityIdentifier("about-settings")
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "0.1.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "1"
    }

    private var author: String { "bravohex" }

    private var copyrightYear: String { "2026" }
}
