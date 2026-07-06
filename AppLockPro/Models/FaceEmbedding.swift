import Foundation

/// Represents a stored face embedding for authentication.
struct FaceEmbedding: Codable {
    /// The 512-dimensional embedding vector (ArcFace output).
    let embedding: [Float]

    /// Date when the embedding was generated.
    let dateCreated: Date

    /// Number of face captures used to generate this averaged embedding.
    let captureCount: Int

    /// Embedding vector dimension (should always be 512 for ArcFace).
    var dimension: Int { embedding.count }

    init(embedding: [Float], dateCreated: Date = Date(), captureCount: Int = 1) {
        self.embedding = embedding
        self.dateCreated = dateCreated
        self.captureCount = captureCount
    }
}
