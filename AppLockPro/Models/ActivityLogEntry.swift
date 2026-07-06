import Foundation

/// Represents a single entry in the activity log.
struct ActivityLogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let eventType: EventType
    let appBundleIdentifier: String?
    let appName: String?
    let authMethod: AuthMethod?
    let wasSuccessful: Bool
    let confidenceScore: Float?
    let details: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        eventType: EventType,
        appBundleIdentifier: String? = nil,
        appName: String? = nil,
        authMethod: AuthMethod? = nil,
        wasSuccessful: Bool = true,
        confidenceScore: Float? = nil,
        details: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.appBundleIdentifier = appBundleIdentifier
        self.appName = appName
        self.authMethod = authMethod
        self.wasSuccessful = wasSuccessful
        self.confidenceScore = confidenceScore
        self.details = details
    }

    /// Types of events tracked in the activity log.
    enum EventType: String, Codable, CaseIterable {
        case appOpened = "App Opened"
        case authSuccess = "Authentication Success"
        case authFailure = "Authentication Failure"
        case appProtected = "App Protected"
        case appUnprotected = "App Unprotected"
        case enrollmentCompleted = "Enrollment Completed"
        case settingsChanged = "Settings Changed"
        case sessionExpired = "Session Expired"
        case lockout = "Lockout Triggered"

        var icon: String {
            switch self {
            case .appOpened:            return "arrow.up.forward.app"
            case .authSuccess:          return "checkmark.shield.fill"
            case .authFailure:          return "xmark.shield.fill"
            case .appProtected:         return "lock.fill"
            case .appUnprotected:       return "lock.open.fill"
            case .enrollmentCompleted:  return "person.crop.circle.badge.checkmark"
            case .settingsChanged:      return "gearshape.fill"
            case .sessionExpired:       return "clock.badge.xmark"
            case .lockout:              return "exclamationmark.lock.fill"
            }
        }

        var color: String {
            switch self {
            case .authSuccess, .enrollmentCompleted: return "green"
            case .authFailure, .lockout:             return "red"
            case .appOpened, .sessionExpired:         return "blue"
            default:                                  return "gray"
            }
        }
    }
}
