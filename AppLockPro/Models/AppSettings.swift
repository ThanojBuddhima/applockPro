import Foundation

/// User-configurable application settings.
class AppSettings: ObservableObject {
    // MARK: - General
    @Published var launchAtStartup: Bool = false
    @Published var startMinimized: Bool = false

    // MARK: - Security
    @Published var faceUnlockEnabled: Bool = true
    @Published var touchIDEnabled: Bool = true
    @Published var macPasswordEnabled: Bool = true
    @Published var pinEnabled: Bool = false

    @Published var confidenceThreshold: Float = Constants.FaceRecognition.defaultConfidenceThreshold
    @Published var maxFailedAttempts: Int = Constants.Authentication.maxFailedAttempts
    @Published var lockAfterSleep: Bool = true
    @Published var lockAfterScreenSaver: Bool = true

    // MARK: - Session
    @Published var sessionTimeout: SessionTimeout = .thirtyMinutes

    // MARK: - Camera
    @Published var selectedCameraID: String? = nil
    @Published var livenessDetectionEnabled: Bool = true

    // MARK: - Privacy
    @Published var captureFailedAttemptPhoto: Bool = false

    /// Predefined session timeout durations.
    enum SessionTimeout: String, CaseIterable, Identifiable, Codable {
        case always = "Always Authenticate"
        case fiveMinutes = "5 Minutes"
        case tenMinutes = "10 Minutes"
        case thirtyMinutes = "30 Minutes"
        case oneHour = "1 Hour"
        case untilLogout = "Until Logout"

        var id: String { rawValue }

        /// Returns the timeout duration in seconds, or nil for 'always' and 'untilLogout'.
        var seconds: TimeInterval? {
            switch self {
            case .always:        return 0
            case .fiveMinutes:   return 300
            case .tenMinutes:    return 600
            case .thirtyMinutes: return 1800
            case .oneHour:       return 3600
            case .untilLogout:   return nil
            }
        }
    }
}
