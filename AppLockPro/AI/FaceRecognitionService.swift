import Foundation
import CoreVideo
import Accelerate
import Vision
import CoreML

/// Uses the real ArcFace (CoreML) model to extract 512-dimensional face embeddings and provides cosine similarity math.
class FaceRecognitionService {
    static let shared = FaceRecognitionService()
    
    // Configurable threshold for matching faces (ArcFace usually uses around 0.5 - 0.6)
    var similarityThreshold: Float {
        let stored = UserDefaults.standard.double(forKey: "confidenceThreshold")
        return stored > 0 ? Float(stored) : 0.55
    }
    
    private var visionModel: VNCoreMLModel?
    
    private func logToFile(_ message: String) {
        print(message)
        let logFileURL = URL(fileURLWithPath: "/Users/thanojbuddhima/Development/applockPro/app_logs.txt")
        let logMessage = "[\(Date())] \(message)\n"
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }

    private init() {
        // Load the real ArcFace CoreML model
        do {
            let config = MLModelConfiguration()
            let arcFace = try ArcFaceModel(configuration: config)
            self.visionModel = try VNCoreMLModel(for: arcFace.model)
        } catch {
            logToFile("Failed to load ArcFace model: \(error)")
        }
    }
    
    /// Generates a 512-d embedding from a CVPixelBuffer using ArcFace.
    func generateEmbedding(from pixelBuffer: CVPixelBuffer, faceRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1), completion: @escaping ([Float]?) -> Void) {
        guard let visionModel = visionModel else {
            completion(nil)
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            guard error == nil,
                  let results = request.results as? [VNCoreMLFeatureValueObservation],
                  let firstResult = results.first,
                  let multiArray = firstResult.featureValue.multiArrayValue else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Convert MLMultiArray to [Float]
            var embedding = [Float](repeating: 0, count: 512)
            let count = min(multiArray.count, 512)
            
            for i in 0..<count {
                embedding[i] = multiArray[i].floatValue
            }
            
            // L2 Normalize
            let normalized = self.normalize(embedding: embedding)
            
            DispatchQueue.main.async {
                completion(normalized)
            }
        }
        
        // ArcFace expects the face to be cropped/scaled. Vision handles the scaling automatically.
        // We use .scaleFill or .centerCrop based on the model needs.
        request.imageCropAndScaleOption = .scaleFill
        request.regionOfInterest = faceRect
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform CoreML request: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    /// Computes the Cosine Similarity between two 512-d embeddings using vDSP (Accelerate Framework)
    func computeCosineSimilarity(embeddingA: [Float], embeddingB: [Float]) -> Float {
        guard embeddingA.count == 512, embeddingB.count == 512 else { return 0.0 }
        
        var dotProduct: Float = 0.0
        
        // Fast SIMD dot product
        vDSP_dotpr(embeddingA, 1, embeddingB, 1, &dotProduct, vDSP_Length(embeddingA.count))
        
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
