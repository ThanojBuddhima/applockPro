import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppLockPro] Application launched successfully.")
        // Start monitoring for application launches (App Blocking)
        AppMonitorService.shared.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("[AppLockPro] Application terminating.")
        // Future: Clean up sessions, save state
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running in background / menu bar
    }
}
