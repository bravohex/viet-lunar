import OSLog

public enum AppLog: Sendable {
    public static let subsystem = "com.tuanlm.VietLunar"

    public static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    public static let calendar = Logger(subsystem: subsystem, category: "calendar")
    public static let loginItem = Logger(subsystem: subsystem, category: "login-item")
    public static let preferences = Logger(subsystem: subsystem, category: "preferences")
}

public enum AppPerformance: Sendable {
    public static let signposter = OSSignposter(
        subsystem: AppLog.subsystem,
        category: "performance"
    )
}
