import Foundation

/// Represents the result of an authentication attempt.
struct AuthenticationResult {
    /// Whether authentication was successful.
    let isAuthenticated: Bool

    /// The method used for this attempt.
    let method: AuthMethod

    /// Confidence score (for face recognition, 0.0–1.0). Nil for other methods.
    let confidence: Float?

    /// Timestamp of the attempt.
    let timestamp: Date

    /// Error message if authentication failed.
    let errorMessage: String?

    init(
        isAuthenticated: Bool,
        method: AuthMethod,
        confidence: Float? = nil,
        timestamp: Date = Date(),
        errorMessage: String? = nil
    ) {
        self.isAuthenticated = isAuthenticated
        self.method = method
        self.confidence = confidence
        self.timestamp = timestamp
        self.errorMessage = errorMessage
    }
}
