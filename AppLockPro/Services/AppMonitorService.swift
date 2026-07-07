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
    
    private func logToFile(_ message: String) {
        print(message)
        let logFileURL = URL(fileURLWithPath: "/Users/thanojbuddhima/Development/applockPro/app_logs.txt")
        let logMessage = "[\(Date())] \(message)\n"
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
    
    /// Starts observing NSWorkspace notifications.
    func startMonitoring() {
        logToFile("Starting AppMonitorService...")
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleAppLaunch(notification: notification)
            }
            .store(in: &cancellables)
            
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let bundleId = app.bundleIdentifier else { return }
                
                if AppManager.shared.isAppProtected(bundleIdentifier: bundleId) {
                    self?.logToFile("Protected app terminated: \(bundleId). Invalidating global session.")
                    SessionManager.shared.invalidateSession()
                }
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
            logToFile("Allowing authenticated app to launch: \(bundleId)")
            recentlyAuthenticatedApps.remove(bundleId)
            return
        }
        
        // If there's an active global session, bypass Face ID
        if SessionManager.shared.isSessionActive {
            logToFile("Global session active. Allowing app to launch: \(bundleId)")
            return
        }
        
        // Check if the app is protected
        if AppManager.shared.isAppProtected(bundleIdentifier: bundleId) {
            logToFile("Protected app launched: \(bundleId). Terminating it...")
            
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
                self?.logToFile("Authentication success for \(bundleId)")
                if let url = appURL {
                    // Mark this app as authenticated so we don't block it again when we relaunch it
                    self?.recentlyAuthenticatedApps.insert(bundleId)
                    
                    // Relaunch the app since they passed authentication
                    // Add a small delay because forceTerminate() is asynchronous and macOS might 
                    // ignore the launch request if it thinks the app is still shutting down.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let configuration = NSWorkspace.OpenConfiguration()
                        configuration.createsNewApplicationInstance = false
                        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { app, error in
                            if let error = error {
                                self?.logToFile("Error relaunching app \(bundleId): \(error)")
                            } else {
                                self?.logToFile("Successfully relaunched \(bundleId)")
                            }
                        }
                    }
                }
            } else {
                self?.logToFile("Authentication failure or cancelled for \(bundleId).")
                // App is already terminated, so we do nothing.
            }
        }
    }
}
