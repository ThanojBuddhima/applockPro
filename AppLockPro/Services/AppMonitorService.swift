import Foundation
import AppKit
import Combine
import SwiftUI

/// Monitors application launches and hides protected applications until authenticated.
class AppMonitorService {
    static let shared = AppMonitorService()
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Apps that were just authenticated and are being relaunched (consumed on next launch event)
    private var recentlyAuthenticatedApps: Set<String> = []
    
    /// Per-app authentication timestamps — tracks when each app was last authenticated
    private var appAuthTimestamps: [String: Date] = [:]
    
    /// Guard to prevent simultaneous auth windows
    private var currentlyAuthenticatingBundleId: String? = nil
    
    /// Read session timeout setting — defaults to "Always Authenticate"
    @AppStorage("sessionTimeout") private var sessionTimeoutRaw = AppSettings.SessionTimeout.always.rawValue
    
    private var sessionTimeout: AppSettings.SessionTimeout {
        AppSettings.SessionTimeout(rawValue: sessionTimeoutRaw) ?? .always
    }
    
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
    
    // MARK: - Session Timeout Logic
    
    /// Checks whether a specific app still has a valid authentication based on the Session Timeout setting.
    private func isAppAuthenticated(bundleId: String) -> Bool {
        guard let lastAuthDate = appAuthTimestamps[bundleId] else {
            return false
        }
        
        switch sessionTimeout {
        case .always:
            // "Always Authenticate" — never consider previously authenticated
            return false
            
        case .untilLogout:
            // "Until Logout" — once authenticated, stays authenticated
            return true
            
        default:
            // Time-based — check if the timeout has elapsed
            guard let timeoutSeconds = sessionTimeout.seconds, timeoutSeconds > 0 else { return false }
            let elapsed = Date().timeIntervalSince(lastAuthDate)
            let isValid = elapsed < timeoutSeconds
            logToFile("Session check for \(bundleId): elapsed=\(Int(elapsed))s, timeout=\(Int(timeoutSeconds))s, valid=\(isValid)")
            return isValid
        }
    }
    
    /// Marks an app as authenticated right now.
    private func markAppAuthenticated(bundleId: String) {
        appAuthTimestamps[bundleId] = Date()
        logToFile("Marked \(bundleId) as authenticated at \(Date())")
    }
    
    // MARK: - Start Monitoring
    
    func startMonitoring() {
        logToFile("Starting AppMonitorService... (sessionTimeout=\(sessionTimeout.rawValue))")
        
        // 1. Intercept fresh app launches
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleAppLaunch(notification: notification)
            }
            .store(in: &cancellables)
        
        // 2. Intercept app terminations — clear per-app auth
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let bundleId = app.bundleIdentifier else { return }
                
                if AppManager.shared.isAppProtected(bundleIdentifier: bundleId) {
                    self?.logToFile("Protected app terminated: \(bundleId). Clearing auth timestamp.")
                    self?.appAuthTimestamps.removeValue(forKey: bundleId)
                    self?.recentlyAuthenticatedApps.remove(bundleId)
                }
            }
            .store(in: &cancellables)
        
        // 3. Intercept app activations (app comes to foreground — including reopen from dock)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleAppActivation(notification: notification)
            }
            .store(in: &cancellables)
        
        // NOTE: We intentionally do NOT listen to didDeactivateApplicationNotification.
        // Reason: when our auth overlay appears, macOS deactivates the protected app,
        // which was incorrectly clearing auth state during authentication.
    }
    
    // MARK: - App Activation (close window & reopen from dock)
    
    private func handleAppActivation(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }
        
        // Skip ourselves
        if bundleId == Bundle.main.bundleIdentifier { return }
        
        // If we just authenticated this app and it's being relaunched, allow it
        if recentlyAuthenticatedApps.contains(bundleId) { return }
        
        // If we're already showing an auth window for this app, don't fire again
        if currentlyAuthenticatingBundleId == bundleId { return }
        
        // Check if the app still has a valid session based on the timeout setting
        if isAppAuthenticated(bundleId: bundleId) { return }
        
        if AppManager.shared.isAppProtected(bundleIdentifier: bundleId) {
            logToFile("Protected app activated: \(bundleId). Requiring auth (timeout=\(sessionTimeout.rawValue))")
            
            let appName = app.localizedName ?? "App"
            
            app.hide()
            
            currentlyAuthenticatingBundleId = bundleId
            
            AuthOverlayWindowController.shared.show(for: appName) { [weak self] success in
                self?.currentlyAuthenticatingBundleId = nil
                if success {
                    self?.logToFile("Activation auth success for \(bundleId)")
                    self?.markAppAuthenticated(bundleId: bundleId)
                    app.unhide()
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
            markAppAuthenticated(bundleId: bundleId)
            return
        }
        
        // If we're already showing an auth window for this app (from activation), don't fire again
        if currentlyAuthenticatingBundleId == bundleId {
            logToFile("Already authenticating \(bundleId) via activation, skipping launch handler.")
            return
        }
        
        // Check if the app still has a valid session based on the timeout setting
        if isAppAuthenticated(bundleId: bundleId) {
            logToFile("App \(bundleId) still has valid session. Allowing launch.")
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
