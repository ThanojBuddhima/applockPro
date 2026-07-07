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

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let isEnrolled = UserDefaults.standard.bool(forKey: "isEnrolled")
        
        if isEnrolled {
            print("[AppLockPro] Auth required to quit. Presenting system auth.")
            SystemAuthService.shared.authenticate(reason: "Authenticate to quit FaceLock Pro") { success in
                if success {
                    print("[AppLockPro] Quit authorized via System Auth.")
                    sender.reply(toApplicationShouldTerminate: true)
                } else {
                    print("[AppLockPro] Quit blocked via System Auth.")
                    sender.reply(toApplicationShouldTerminate: false)
                }
            }
            return .terminateLater
        }
        
        print("[AppLockPro] Not enrolled, allowing immediate quit.")
        return .terminateNow
    }
}
