import Foundation
import SwiftUI
import VietLunarCore

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("Chung", systemImage: "gearshape")
                }

            AboutSettingsView()
                .tabItem {
                    Label("Giới thiệu", systemImage: "info.circle")
                }
        }
        .frame(width: 540, height: 440)
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Cài đặt VietLunar")
                .font(.title2.bold())
                .accessibilityIdentifier("settings-title")
                .padding(.horizontal, 20)
                .padding(.top, 16)

            Form {
                Section("Thanh menu") {
                Picker("Nội dung", selection: titleFormatBinding) {
                    ForEach(MenuBarTitleFormat.allCases, id: \.self) { format in
                        Text(format.vietnameseName).tag(format)
                    }
                }
                .accessibilityIdentifier("title-format-picker")

                Toggle("Hiện ngày dương", isOn: solarDateBinding)
                    .disabled(appState.preferences.titleFormat.isIconOnly)
                    .accessibilityIdentifier("show-solar-date-toggle")

                Toggle("Hiện Can–Chi ngày", isOn: dayCanChiBinding)
                    .disabled(appState.preferences.titleFormat.isIconOnly)
                    .accessibilityIdentifier("show-day-can-chi-toggle")

                Toggle("Hiện đồng hồ", isOn: clockBinding)
                    .accessibilityIdentifier("show-clock-toggle")

                Toggle("Dùng định dạng 24 giờ", isOn: uses24HourClockBinding)
                    .disabled(!appState.preferences.showsClock)
                    .accessibilityIdentifier("use-24-hour-toggle")

                LabeledContent("Xem trước") {
                    Text(menuTitlePreview)
                        .monospacedDigit()
                        .accessibilityIdentifier("menu-title-preview")
                }
            }

                Section("Lịch") {
                Picker("Tuần bắt đầu vào", selection: weekStartBinding) {
                    ForEach(WeekStart.allCases, id: \.self) { weekStart in
                        Text(weekStart.vietnameseName).tag(weekStart)
                    }
                }
                .accessibilityIdentifier("week-start-picker")

                LabeledContent("Quy ước Can–Chi") {
                    Text(dayBoundaryDescription)
                }
                Text("Ngày âm và Can–Chi được tính theo lịch Việt Nam UTC+7.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

                Section("Hệ thống") {
                Toggle("Mở VietLunar khi đăng nhập", isOn: .constant(false))
                    .disabled(true)
                    .accessibilityIdentifier("launch-at-login-toggle")
                Text("Chưa khả dụng trong bản dựng này.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

                if let errorMessage = appState.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)
        }
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

    private var menuTitlePreview: String {
        if appState.preferences.titleFormat.isIconOnly {
            return appState.menuBarPresentation.title.map { "☾  \($0)" } ?? "☾"
        }
        return appState.menuBarPresentation.title ?? "ÂL"
    }

    private var dayBoundaryDescription: String {
        switch appState.preferences.canChiBoundaryPolicy {
        case .civilMidnight:
            "Đổi ngày lúc 00:00"
        case .startOfZiHour:
            "Đổi ngày lúc 23:00"
        }
    }
}

private struct AboutSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("VietLunar")
                    .font(.title.bold())
                Text("Phiên bản \(version)")
                    .foregroundStyle(.secondary)

                GroupBox("Phạm vi và quy ước") {
                    Text("Hỗ trợ ngày dương từ 01/01/1800 đến 31/12/2199. Lịch âm Việt Nam và Can–Chi dùng quy ước UTC+7.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Quyền riêng tư") {
                    Text("Ứng dụng chạy offline, không yêu cầu tài khoản và không gửi dữ liệu cá nhân ra ngoài máy Mac.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Nguồn đối chiếu") {
                    Text("Quy tắc và kết quả được đối chiếu với tài liệu của Hồ Ngọc Đức, Calendrical Calculations (Edward M. Reingold và Nachum Dershowitz), cùng Hermetic Systems. Không nhúng mã nguồn của các tài liệu này.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("Chỉ sử dụng Apple platform frameworks ở runtime.")
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
}
