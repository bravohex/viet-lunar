import Foundation
import ServiceManagement

public enum LoginItemStatus: Equatable, Sendable {
    case disabled
    case enabled
    case requiresUserApproval
    case unavailable
    case error(String)
}

public enum LoginItemServiceError: Error {
    case requiresInstallation
}

protocol LoginItemRegistering {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

extension SMAppService: LoginItemRegistering {}

public protocol LoginItemServicing: Sendable {
    var requiresInstallation: Bool { get }
    func status() -> LoginItemStatus
    func setEnabled(_ enabled: Bool) throws
    func openSystemSettings()
}

public extension LoginItemServicing {
    var requiresInstallation: Bool { false }
}

public final class SMLoginItemService: LoginItemServicing, @unchecked Sendable {
    private let service: any LoginItemRegistering
    private let bundleURL: URL

    public convenience init(service: SMAppService = .mainApp) {
        self.init(registration: service, bundleURL: Bundle.main.bundleURL)
    }

    init(registration: any LoginItemRegistering, bundleURL: URL) {
        self.bundleURL = bundleURL
        self.service = registration
    }

    public func status() -> LoginItemStatus {
        return Self.map(status: service.status)
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled && requiresInstallation {
            throw LoginItemServiceError.requiresInstallation
        }
        let currentStatus = status()
        if enabled,
           currentStatus == .enabled || currentStatus == .requiresUserApproval {
            return
        }
        if !enabled, currentStatus == .disabled {
            return
        }

        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }

    public func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    public var requiresInstallation: Bool {
        let path = bundleURL.standardizedFileURL.resolvingSymlinksInPath().path
        let components = bundleURL.pathComponents
        return components.contains("AppTranslocation")
            || components.contains("DerivedData") || components.contains(".build")
            || path.hasPrefix("/Volumes/") || path.hasPrefix("/private/var/folders/")
            || path.hasPrefix("/private/tmp/") || path.hasPrefix("/tmp/")
    }

    public static func map(status: SMAppService.Status) -> LoginItemStatus {
        switch status {
        case .notRegistered:
            .disabled
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresUserApproval
        case .notFound:
            .unavailable
        @unknown default:
            .unavailable
        }
    }
}
