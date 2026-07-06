import Foundation
import AppKit

/// Represents an application that the user has chosen to protect with FaceLock Pro.
struct ProtectedApp: Identifiable, Codable, Hashable {
    /// Unique identifier.
    let id: UUID

    /// The application's display name (e.g., "Safari").
    let name: String

    /// The application's bundle identifier (e.g., "com.apple.Safari").
    let bundleIdentifier: String

    /// The file path to the application bundle (e.g., "/Applications/Safari.app").
    let path: String

    /// Whether the application is currently protected (locked).
    var isProtected: Bool

    /// Date when the app was added to the protected list.
    let dateAdded: Date

    init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        path: String,
        isProtected: Bool = true,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.isProtected = isProtected
        self.dateAdded = dateAdded
    }
}

/// Represents an installed application discovered on the system (for the app picker).
struct InstalledApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let path: String
    let icon: NSImage

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
    }
}
