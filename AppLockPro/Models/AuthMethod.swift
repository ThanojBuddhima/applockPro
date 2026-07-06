import Foundation

/// The method used for authentication.
enum AuthMethod: String, Codable, CaseIterable, Identifiable {
    case faceUnlock = "Face Unlock"
    case touchID = "Touch ID"
    case password = "macOS Password"
    case pin = "PIN"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .faceUnlock: return "faceid"
        case .touchID:    return "touchid"
        case .password:   return "key.fill"
        case .pin:        return "number.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .faceUnlock: return "Authenticate using facial recognition"
        case .touchID:    return "Authenticate using Touch ID sensor"
        case .password:   return "Authenticate using macOS login password"
        case .pin:        return "Authenticate using your application PIN"
        }
    }
}
