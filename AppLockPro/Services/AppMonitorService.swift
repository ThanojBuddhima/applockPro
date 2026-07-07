import Foundation
import AppKit
import Combine

/// Monitors application launches and hides protected applications until authenticated.
class AppMonitorService {
    static let shared = AppMonitorService()
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Apps that were just authenticated and are being relaunched (consumed on next launch event)
    private var recentlyAuthenticatedApps: Set<String> = []
    
    /// Apps that are currently in the foreground and have been authenticated this activation cycle.
    /// Cleared when the app is deactivated (loses focus).
    private var authenticatedActiveApps: Set<String> = []
    
    /// Guard to prevent simultaneous auth windows (e.g. launch + activate firing at the same time)
    private var currentlyAuthenticatingBundleId: String? = nil
    
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
        
        // 1. Intercept fresh app launches
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleAppLaunch(notification: notification)
            }
            .store(in: &cancellables)
        
        // 2. Intercept app terminations — clear per-app state
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let bundleId = app.bundleIdentifier else { return }
                
                if AppManager.shared.isAppProtected(bundleIdentifier: bundleId) {
                    self?.logToFile("Protected app terminated: \(bundleId). Clearing per-app auth.")
                    self?.authenticatedActiveApps.remove(bundleId)
                    self?.recentlyAuthenticatedApps.remove(bundleId)
                }
            }
            .store(in: &cancellables)
        
        // 3. Intercept app activations (when an app comes to foreground — including close & reopen from dock)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleAppActivation(notification: notification)
            }
            .store(in: &cancellables)
        
        // 4. Intercept app deactivations (when an app loses focus) — clear per-app auth
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didDeactivateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let bundleId = app.bundleIdentifier else { return }
                
                if AppManager.shared.isAppProtected(bundleIdentifier: bundleId) {
                    self?.logToFile("Protected app deactivated: \(bundleId). Clearing per-app auth.")
                    self?.authenticatedActiveApps.remove(bundleId)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - App Activation (close window & reopen from dock)
    
    private func handleAppActivation(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }
        
        if bundleId == Bundle.main.bundleIdentifier { return }
        
        // If we just authenticated this app and it's being relaunched, allow it
        if recentlyAuthenticatedApps.contains(bundleId) { return }
        
        // If already authenticated during this activation cycle, allow it
        if authenticatedActiveApps.contains(bundleId) { return }
        
        // If we're already showing an auth window for this app, don't fire again
        if currentlyAuthenticatingBundleId == bundleId { return }
        
        if AppManager.shared.isAppProtected(bundleIdentifier: bundleId) {
            logToFile("Protected app activated: \(bundleId). Hiding it for auth...")
            
            let appName = app.localizedName ?? "App"
            
            app.hide()
            
            currentlyAuthenticatingBundleId = bundleId
            
            AuthOverlayWindowController.shared.show(for: appName) { [weak self] success in
                self?.currentlyAuthenticatingBundleId = nil
                if success {
                    self?.logToFile("Activation auth success for \(bundleId)")
                    self?.authenticatedActiveApps.insert(bundleId)
                    // Unhide the app
                    app.unhide()
                    // Bring the app back to front
                    app.activate()
                } else {
                    self?.logToFile("Activation auth failure for \(bundleId). Keeping hidden.")
                }
            }
        }
    }
    
    // MARK: - Fresh App Launch
    
    private func handleAppLaunch(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }
        
        if bundleId == Bundle.main.bundleIdentifier { return }
        
        // If we recently authenticated this app and relaunched it, allow it
        if recentlyAuthenticatedApps.contains(bundleId) {
            logToFile("Allowing authenticated app to launch: \(bundleId)")
            recentlyAuthenticatedApps.remove(bundleId)
            authenticatedActiveApps.insert(bundleId)
            return
        }
        
        // If we're already showing an auth window for this app (from activation), don't fire again
        if currentlyAuthenticatingBundleId == bundleId {
            logToFile("Already authenticating \(bundleId) via activation, skipping launch handler.")
            return
        }
        
        if AppManager.shared.isAppProtected(bundleIdentifier: bundleId) {
            logToFile("Protected app launched: \(bundleId). Terminating it...")
            
            let appURL = app.bundleURL
            let appName = app.localizedName ?? "App"
            
            app.forceTerminate()
            
            currentlyAuthenticatingBundleId = bundleId
            
            AuthOverlayWindowController.shared.show(for: appName) { [weak self] success in
                self?.currentlyAuthenticatingBundleId = nil
                if success {
                    self?.logToFile("Launch auth success for \(bundleId)")
                    if let url = appURL {
                        self?.recentlyAuthenticatedApps.insert(bundleId)
                        
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
                    self?.logToFile("Launch auth failure or cancelled for \(bundleId).")
                }
            }
        }
    }
}

