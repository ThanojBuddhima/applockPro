import SwiftUI

/// Sidebar navigation for the main application window.
struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(selection: $appState.selectedNavItem) {
            Section("Main") {
                ForEach([NavigationItem.dashboard, .protectedApps]) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                    }
                }
            }

            Section("Security") {
                ForEach([NavigationItem.enrollment, .history]) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                    }
                }
            }

            Section("Application") {
                ForEach([NavigationItem.settings, .about]) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("FaceLock Pro")
    }
}

#Preview {
    SidebarView()
        .environmentObject(AppState())
        .frame(width: 220, height: 500)
}
