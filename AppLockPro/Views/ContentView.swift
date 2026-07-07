import SwiftUI

/// The root view of the application. Manages routing between onboarding and main app.
struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.onboardingCompleted {
                WelcomeView()
            } else if !appState.isAppUnlocked {
                AppLockedView()
            } else {
                MainAppView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.onboardingCompleted)
        .animation(.easeInOut(duration: 0.3), value: appState.isAppUnlocked)
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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToDashboard"))) { _ in
            appState.selectedNavItem = .dashboard
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToSettings"))) { _ in
            appState.selectedNavItem = .settings
        }
    }
}

/// A view shown when the app dashboard is locked, prompting for system authentication.
struct AppLockedView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("AppLock Pro is locked")
                .font(.title2)
                .fontWeight(.medium)
            Text("Please authenticate to access your dashboard and settings.")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("Unlock") {
                authenticate()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            authenticate()
        }
    }
    
    private func authenticate() {
        AuthOverlayWindowController.shared.show(for: "AppLock Pro") { success in
            if success {
                DispatchQueue.main.async {
                    appState.isAppUnlocked = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 1000, height: 700)
}
