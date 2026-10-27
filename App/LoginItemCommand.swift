import Foundation
import VietLunarInfrastructure

/// Explicit maintenance commands also allow checking the signed, installed app.
enum LoginItemCommand: String {
    case status = "--login-item-status"
    case enable = "--enable-login-item"
    case disable = "--disable-login-item"

    func execute(using service: any LoginItemServicing) -> (exitCode: Int32, message: String) {
        do {
            switch self {
            case .status: break
            case .enable: try service.setEnabled(true)
            case .disable: try service.setEnabled(false)
            }
        } catch LoginItemServiceError.requiresInstallation {
            return (1, "Login item: install VietLunar in Applications and run this command from the installed app.")
        } catch {
            return (1, "Login item error: \(error.localizedDescription)")
        }
        let current = service.status()
        let description: String
        switch current {
        case .enabled: description = "enabled"
        case .disabled: description = "disabled"
        case .requiresUserApproval: description = "requires approval in System Settings > General > Login Items"
        case .unavailable: description = "unavailable"
        case .error(let message): description = "error: \(message)"
        }
        let satisfied = self == .status || (self == .enable && current == .enabled)
            || (self == .disable && current == .disabled)
        let locationNote = service.requiresInstallation
            ? "\nInstall the app in Applications before enabling launch at login." : ""
        return (satisfied ? 0 : 1, "Login item: \(description)\(locationNote)")
    }
}
