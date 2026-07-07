import SwiftUI

@main
struct AppLockProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @AppStorage("appTheme") private var appTheme: String = "system"

    var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(colorScheme)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1000, height: 700)

        Settings {
            SettingsView()
                .environmentObject(appState)
                .preferredColorScheme(colorScheme)
        }
    }
}
