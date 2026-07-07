import SwiftUI

/// The root view of the application. Manages routing between onboarding and main app.
struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.onboardingCompleted {
                WelcomeView()
            } else {
                MainAppView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.onboardingCompleted)
    }
}

/// The main application view with sidebar navigation.
struct MainAppView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            Group {
                switch appState.selectedNavItem {
                case .dashboard:
                    DashboardView()
                case .protectedApps:
                    ProtectedAppsView()
                case .enrollment:
                    EnrollmentWizardView()
                case .settings:
                    SettingsView()
                case .about:
                    AboutView()
                case .none:
                    DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 1000, height: 700)
}
