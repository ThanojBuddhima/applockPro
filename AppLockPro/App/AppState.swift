import SwiftUI

/// Shared application state that flows through the entire view hierarchy.
class AppState: ObservableObject {
    /// Whether the user has completed the initial face enrollment.
    @Published var isEnrolled: Bool = false

    /// Whether all required permissions (camera, accessibility) have been granted.
    @Published var permissionsGranted: Bool = false

    /// Whether the onboarding / welcome flow has been completed.
    @Published var onboardingCompleted: Bool = false

    /// The currently selected sidebar navigation item.
    @Published var selectedNavItem: NavigationItem? = .dashboard
}

/// Represents a navigation destination in the sidebar.
enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case protectedApps = "Protected Apps"
    case enrollment = "Face Enrollment"
    case history = "Activity History"
    case settings = "Settings"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:      return "gauge.with.dots.needle.33percent"
        case .protectedApps:  return "lock.shield"
        case .enrollment:     return "faceid"
        case .history:        return "clock.arrow.circlepath"
        case .settings:       return "gearshape"
        case .about:          return "info.circle"
        }
    }
}
