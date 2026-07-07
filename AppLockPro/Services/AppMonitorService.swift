import Foundation
import AppKit
import Combine

/// Monitors application launches and hides protected applications until authenticated.
class AppMonitorService {
    static let shared = AppMonitorService()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Apps that have been successfully authenticated and are allowed to launch
    private var recentlyAuthenticatedApps: Set<String> = []
    
    private init() {}
    
    /// Starts observing NSWorkspace notifications.
    func startMonitoring() {
        print("Starting AppMonitorService...")
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleAppLaunch(notification: notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleAppLaunch(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }
        
        // Skip ourselves
        if bundleId == Bundle.main.bundleIdentifier { return }
        
        // If we recently authenticated this app and relaunched it, allow it to pass and remove it from the bypass list
        if recentlyAuthenticatedApps.contains(bundleId) {
            print("Allowing authenticated app to launch: \(bundleId)")
            recentlyAuthenticatedApps.remove(bundleId)
            return
        }
        
        // If there's an active global session, bypass Face ID
        if SessionManager.shared.isSessionActive {
            print("Global session active. Allowing app to launch: \(bundleId)")
            return
        }
        
        // Check if the app is protected
        if AppManager.shared.isAppProtected(bundleIdentifier: bundleId) {
            print("Protected app launched: \(bundleId). Terminating it...")
            
            // Capture the URL so we can relaunch it
            let appURL = app.bundleURL
            let appName = app.localizedName ?? "App"
            
            // Option B: Terminate the application immediately.
            // forceTerminate() is more aggressive and ensures the app dies before it can render its windows.
            app.forceTerminate()
            
            // Present authentication overlay
            showAuthenticationOverlay(for: bundleId, appName: appName, appURL: appURL)
        }
    }
    
    private func showAuthenticationOverlay(for bundleId: String, appName: String, appURL: URL?) {
        AuthOverlayWindowController.shared.show(for: appName) { [weak self] success in
            if success {
                print("Authentication success for \(bundleId)")
                if let url = appURL {
                    // Mark this app as authenticated so we don't block it again when we relaunch it
                    self?.recentlyAuthenticatedApps.insert(bundleId)
                    
                    // Relaunch the app since they passed authentication
                    let configuration = NSWorkspace.OpenConfiguration()
                    NSWorkspace.shared.openApplication(at: url, configuration: configuration, completionHandler: nil)
                }
            } else {
                print("Authentication failure or cancelled for \(bundleId).")
                // App is already terminated, so we do nothing.
            }
        }
    }
}
