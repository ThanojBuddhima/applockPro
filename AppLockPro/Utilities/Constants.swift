import Foundation

/// Application-wide constants.
enum Constants {
    /// App metadata
    enum App {
        static let name = "AppLock Pro"
        static let bundleIdentifier = "com.applockpro.facelockpro"
        static let version = "1.0.0"
    }

    /// Face recognition settings
    enum FaceRecognition {
        /// Number of face images to capture during enrollment.
        static let enrollmentImageCount = 25

        /// Minimum confidence score to accept authentication (0.0–1.0).
        static let defaultConfidenceThreshold: Float = 0.55

        /// ArcFace embedding dimension.
        static let embeddingDimension = 512

        /// Input image size for ArcFace model.
        static let faceInputSize = 112
    }

    /// Authentication settings
    enum Authentication {
        /// Maximum failed attempts before cooldown.
        static let maxFailedAttempts = 5

        /// Cooldown duration in seconds after max failed attempts.
        static let cooldownDuration: TimeInterval = 60

        /// Default session timeout in seconds (30 minutes).
        static let defaultSessionTimeout: TimeInterval = 1800

        /// PIN minimum length.
        static let pinMinLength = 4

        /// PIN maximum length.
        static let pinMaxLength = 8
    }

    /// Keychain keys
    enum Keychain {
        static let faceEmbeddingKey = "com.applockpro.face.embedding"
        static let pinKey = "com.applockpro.auth.pin"
    }

    /// UserDefaults keys
    enum Defaults {
        static let isEnrolled = "isEnrolled"
        static let onboardingCompleted = "onboardingCompleted"
        static let launchAtStartup = "launchAtStartup"
        static let sessionTimeout = "sessionTimeout"
        static let confidenceThreshold = "confidenceThreshold"
        static let maxFailedAttempts = "maxFailedAttempts"
        static let lockAfterSleep = "lockAfterSleep"
        static let faceUnlockEnabled = "faceUnlockEnabled"
        static let touchIDEnabled = "touchIDEnabled"
        static let pinEnabled = "pinEnabled"
    }
}
