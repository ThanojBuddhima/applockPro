import Foundation
import CoreVideo
import Accelerate

/// Simulates extracting 512-dimensional face embeddings and provides cosine similarity math.
class FaceRecognitionService {
    static let shared = FaceRecognitionService()
    
    // Configurable threshold for matching faces (ArcFace usually uses around 0.5 - 0.6)
    let similarityThreshold: Float = 0.60
    
    private init() {}
    
    /// Simulates generating a 512-d embedding from a CVPixelBuffer.
    /// In a real app, this would preprocess the buffer and run it through a CoreML model.
    func generateEmbedding(from pixelBuffer: CVPixelBuffer, completion: @escaping ([Float]?) -> Void) {
        // Simulate a heavy ML extraction workload (about 150ms on Apple Silicon)
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.15) {
            // For the sake of this prototype without an ArcFace model, 
            // we will generate a consistent "dummy" embedding based on the current timestamp 
            // or just a hardcoded array if we want it to always match.
            // Since we want the user to be able to lock and unlock, we return a standard "user" embedding.
            var dummyEmbedding = [Float](repeating: 0, count: 512)
            dummyEmbedding[0] = 0.9 // Give it some feature
            dummyEmbedding[511] = 0.1
            
            // Normalize it just like a real embedding would be
            let normalized = self.normalize(embedding: dummyEmbedding)
            
            DispatchQueue.main.async {
                completion(normalized)
            }
        }
    }
    
    /// Computes the Cosine Similarity between two 512-d embeddings using vDSP (Accelerate Framework)
    func computeCosineSimilarity(embeddingA: [Float], embeddingB: [Float]) -> Float {
        guard embeddingA.count == 512, embeddingB.count == 512 else { return 0.0 }
        
        var dotProduct: Float = 0.0
        
        // Fast SIMD dot product
        vDSP_dotpr(embeddingA, 1, embeddingB, 1, &dotProduct, vDSP_Length(embeddingA.count))
        
        // Since the embeddings should already be L2-normalized, the dot product IS the cosine similarity.
        // However, we can calculate magnitudes just to be safe.
        var magA: Float = 0.0
        var magB: Float = 0.0
        
        vDSP_svesq(embeddingA, 1, &magA, vDSP_Length(embeddingA.count))
        vDSP_svesq(embeddingB, 1, &magB, vDSP_Length(embeddingB.count))
        
        let magnitude = sqrt(magA) * sqrt(magB)
        if magnitude == 0 { return 0.0 }
        
        return dotProduct / magnitude
    }
    
    /// L2 Normalization
    private func normalize(embedding: [Float]) -> [Float] {
        var magSQ: Float = 0.0
        vDSP_svesq(embedding, 1, &magSQ, vDSP_Length(embedding.count))
        let mag = sqrt(magSQ)
        
        if mag == 0 { return embedding }
        
        var normalized = [Float](repeating: 0, count: embedding.count)
        var divisor = mag
        vDSP_vsdiv(embedding, 1, &divisor, &normalized, 1, vDSP_Length(embedding.count))
        
        return normalized
    }
}
