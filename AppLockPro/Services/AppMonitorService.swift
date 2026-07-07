import Foundation
import AppKit
import Combine
import SwiftUI

/// Monitors application launches and hides/suspends protected applications until authenticated.
class AppMonitorService {
    static let shared = AppMonitorService()
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Per-app authentication timestamps — tracks when each app was last authenticated
    private var appAuthTimestamps: [String: Date] = [:]
    
    /// Guard to prevent simultaneous auth windows
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
    
    /// Marks an app as authenticated right now.
    private func markAppAuthenticated(bundleId: String) {
        appAuthTimestamps[bundleId] = Date()
        logToFile("Marked \(bundleId) as authenticated at \(Date())")
    }
    
    // MARK: - Process Suspension Helpers
    
    private func suspendProcess(pid: pid_t) {
        kill(pid, SIGSTOP)
        logToFile("Suspended process PID: \(pid)")
    }
    
    private func resumeProcess(pid: pid_t) {
        kill(pid, SIGCONT)
        logToFile("Resumed process PID: \(pid)")
    }
    
    // MARK: - Start Monitoring
    
    func startMonitoring() {
        logToFile("Starting AppMonitorService (with SIGSTOP locking)...")
        
        // 1. Intercept fresh app launches
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleAppEvent(notification: notification, eventType: "Launch")
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
                }
            }
            .store(in: &cancellables)
        
        // 3. Intercept app activations (app comes to foreground — including reopen from dock)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleAppEvent(notification: notification, eventType: "Activation")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Shared Event Handler (Launch & Activation)
    
    private func handleAppEvent(notification: Notification, eventType: String) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }
        
        // Skip ourselves
        if bundleId == Bundle.main.bundleIdentifier { return }
        
        // If we're already showing an auth window for this app, don't fire again
        if currentlyAuthenticatingBundleId == bundleId { return }
        
        // Grace period: ignore events that happen within 3 seconds of a successful auth.
        // This prevents infinite loops when we call `app.activate()` after auth success.
        if let lastAuth = appAuthTimestamps[bundleId], Date().timeIntervalSince(lastAuth) < 3.0 {
            logToFile("Ignoring \(eventType) for \(bundleId) - within 3s grace period.")
            return
        }
        
        if AppManager.shared.isAppProtected(bundleIdentifier: bundleId) {
            logToFile("Protected app event (\(eventType)): \(bundleId). Locking app...")
            
            let appName = app.localizedName ?? "App"
            
            // 1. Hide the window so it disappears from screen
            app.hide()
            
            // 2. Suspend the process so it literally stops running in the background
            suspendProcess(pid: app.processIdentifier)
            
            currentlyAuthenticatingBundleId = bundleId
            
            AuthOverlayWindowController.shared.show(for: appName) { [weak self] success in
                self?.currentlyAuthenticatingBundleId = nil
                
                if success {
                    self?.logToFile("\(eventType) auth success for \(bundleId)")
                    self?.markAppAuthenticated(bundleId: bundleId)
                    
                    // Unfreeze and show
                    self?.resumeProcess(pid: app.processIdentifier)
                    app.unhide()
                    app.activate()
                } else {
                    self?.logToFile("\(eventType) auth failure for \(bundleId). Keeping suspended and hidden.")
                    // Leave it suspended. The process is completely frozen.
                }
            }
        }
    }
}
