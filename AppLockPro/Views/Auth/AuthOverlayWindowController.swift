import SwiftUI
import AppKit

/// Borderless panel that can sit over the menu bar / notch and become key for auth fallbacks.
final class NotchAuthPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Presents Face ID unlock as an island that expands from the top notch.
class AuthOverlayWindowController: NSWindowController {
    static let shared = AuthOverlayWindowController()

    private var completion: ((Bool) -> Void)?

    private init() {
        let geometry = NotchGeometry.current()
        let panel = NotchAuthPanel(
            contentRect: geometry.windowFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.animationBehavior = .none
        panel.isExcludedFromWindowsMenu = true
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.ignoresMouseEvents = true

        super.init(window: panel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(for appName: String, completion: @escaping (Bool) -> Void) {
        if let existingCompletion = self.completion {
            existingCompletion(false)
        }

        self.completion = completion

        let animationEnabled = UserDefaults.standard.object(forKey: Constants.Defaults.unlockAnimationEnabled) as? Bool ?? true
        let geometry = NotchGeometry.current()

        let overlayView = AuthNotchView(
            appName: appName,
            animationEnabled: animationEnabled,
            collapsedSize: CGSize(width: geometry.collapsedSize.width, height: geometry.collapsedSize.height),
            expandedSize: CGSize(width: geometry.expandedSize.width, height: geometry.expandedSize.height)
        ) { [weak self] success in
            self?.closeWindow(success: success)
        }

        let hostingController = NSHostingController(rootView: AnyView(overlayView.id(UUID())))
        hostingController.sizingOptions = []
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor

        window?.contentViewController = hostingController
        window?.setFrame(geometry.windowFrame, display: true)
        window?.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)

        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func closeWindow(success: Bool) {
        window?.orderOut(nil)
        completion?(success)
        completion = nil
    }
}
