import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppLockPro] Application launched successfully.")
        // Future: Start AppMonitorService, check enrollment status
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("[AppLockPro] Application terminating.")
        // Future: Clean up sessions, save state
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running in background / menu bar
    }
}
