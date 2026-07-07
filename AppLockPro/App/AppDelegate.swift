import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppLockPro] Application launched successfully.")
        // Start monitoring for application launches (App Blocking)
        AppMonitorService.shared.startMonitoring()
        
        setupMenuBar()
        updateDockVisibility()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                appIcon.size = NSSize(width: 18, height: 18)
                button.image = appIcon
            } else {
                button.image = NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: "AppLock Pro")
            }
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Dashboard", action: #selector(showMainWindow), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit AppLock Pro", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = false
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: config)
        
        // Use NotificationCenter to tell the UI to change tabs if needed
        NotificationCenter.default.post(name: Notification.Name("NavigateToDashboard"), object: nil)
        
        for window in NSApp.windows {
            if window.className == "SwiftUI.AppKitWindow" {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }
    
    @objc func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = false
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: config)
        
        NotificationCenter.default.post(name: Notification.Name("NavigateToSettings"), object: nil)
        
        for window in NSApp.windows {
            if window.className == "SwiftUI.AppKitWindow" {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }
    
    func updateDockVisibility() {
        let hideDockIcon = UserDefaults.standard.bool(forKey: "hideDockIcon")
        if hideDockIcon {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }
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
            SystemAuthService.shared.authenticate(reason: "Authenticate to quit AppLock Pro") { success in
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
