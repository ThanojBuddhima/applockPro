import AppKit

/// Measures the hardware notch (or a top-center fallback) and the expanded island window frame.
struct NotchGeometry {
    static let expandedSize = NSSize(width: 340, height: 120)
    static let fallbackCollapsedSize = NSSize(width: 180, height: 32)
    static let fallbackTopInset: CGFloat = 12

    let screen: NSScreen
    let hasNotch: Bool
    let collapsedSize: NSSize
    let expandedSize: NSSize
    let windowFrame: NSRect

    static func current(on screen: NSScreen? = nil) -> NotchGeometry {
        NotchGeometry(screen: screen ?? targetScreen())
    }

    static func targetScreen() -> NSScreen {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    init(screen: NSScreen) {
        self.screen = screen

        let frame = screen.frame
        let left = screen.auxiliaryTopLeftArea ?? .zero
        let right = screen.auxiliaryTopRightArea ?? .zero
        let notchWidth = frame.width - left.width - right.width
        let notchHeight = max(left.height, right.height, screen.safeAreaInsets.top)

        let detectedNotch = left.width > 0
            && right.width > 0
            && notchWidth > 80
            && notchWidth < 400
            && notchHeight > 16
            && notchHeight < 48

        self.hasNotch = detectedNotch
        self.collapsedSize = detectedNotch
            ? NSSize(width: notchWidth, height: notchHeight)
            : Self.fallbackCollapsedSize

        let expandedWidth = max(Self.expandedSize.width, self.collapsedSize.width + 24)
        let expandedHeight = Self.expandedSize.height
        self.expandedSize = NSSize(width: expandedWidth, height: expandedHeight)

        let x = frame.midX - expandedWidth / 2
        let y: CGFloat
        if detectedNotch {
            y = frame.maxY - expandedHeight
        } else {
            // Sit just below the menu bar on non-notch displays.
            y = screen.visibleFrame.maxY - Self.fallbackTopInset - expandedHeight
        }
        self.windowFrame = NSRect(x: x, y: y, width: expandedWidth, height: expandedHeight)
    }
}
