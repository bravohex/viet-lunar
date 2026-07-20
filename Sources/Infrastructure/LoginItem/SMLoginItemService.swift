import ServiceManagement

public enum LoginItemStatus: Equatable, Sendable {
    case disabled
    case enabled
    case requiresUserApproval
    case unavailable
    case error(String)
}

public protocol LoginItemServicing: Sendable {
    func status() -> LoginItemStatus
    func setEnabled(_ enabled: Bool) throws
    func openSystemSettings()
}

public final class SMLoginItemService: LoginItemServicing, @unchecked Sendable {
    private let service: SMAppService

    public init(service: SMAppService = .mainApp) {
        self.service = service
    }

    public func status() -> LoginItemStatus {
        Self.map(status: service.status)
    }

    public func setEnabled(_ enabled: Bool) throws {
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
