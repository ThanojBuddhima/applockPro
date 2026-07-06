import Foundation
import os

/// Centralized logging utility using Apple's unified logging system.
enum AppLogger {
    private static let subsystem = Constants.App.bundleIdentifier

    /// General application events.
    static let general = Logger(subsystem: subsystem, category: "general")

    /// Authentication-related events.
    static let auth = Logger(subsystem: subsystem, category: "authentication")

    /// Face recognition and AI pipeline events.
    static let faceAI = Logger(subsystem: subsystem, category: "face-ai")

    /// Camera and capture events.
    static let camera = Logger(subsystem: subsystem, category: "camera")

    /// App monitoring events.
    static let monitor = Logger(subsystem: subsystem, category: "app-monitor")

    /// Security and Keychain events.
    static let security = Logger(subsystem: subsystem, category: "security")
}
