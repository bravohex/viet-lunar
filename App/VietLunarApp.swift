import SwiftUI
import VietLunarCore
import VietLunarInfrastructure

@main
struct VietLunarApp: App {
    var body: some Scene {
        WindowGroup("VietLunar") {
            VStack(spacing: 8) {
                Text("VietLunar")
                    .font(.title)
                Text("\(CoreBuildInfo.name) · \(InfrastructureBuildInfo.name)")
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 320, minHeight: 180)
        }
    }
}
