import Foundation
import Combine
import CoreVideo

enum AuthState {
    case scanning
    case verifying
    case success
    case failure
}

class AuthOverlayViewModel: ObservableObject {
    @Published var authState: AuthState = .scanning
    @Published var statusMessage: String = "Scanning face..."
    
    let cameraService = CameraService()
    let faceDetector = FaceDetectorService()
    
    private var cancellables = Set<AnyCancellable>()
    private var isVerifying = false
    
    var onAuthResult: ((Bool) -> Void)?
    
    init() {
        faceDetector.$currentFace
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.handleFaceResult(result)
            }
            .store(in: &cancellables)
    }
    
    func start() {
        isVerifying = false
        authState = .scanning
        statusMessage = "Scanning face..."
        cameraService.start()
        faceDetector.startProcessing(framePublisher: cameraService.framePublisher)
    }
    
    func stop() {
        cameraService.stop()
        faceDetector.stopProcessing()
    }
    
    private func handleFaceResult(_ result: FaceDetectionResult?) {
        guard !isVerifying, authState == .scanning, let result = result else { return }
        
        // Wait for a good quality face
        if result.quality > 0.4, let buffer = result.pixelBuffer {
            isVerifying = true
            authState = .verifying
            statusMessage = "Verifying..."
            
            // Stop scanning to prevent multiple verifications
            faceDetector.stopProcessing()
            
            verifyFace(buffer: buffer)
        }
    }
    
    private func verifyFace(buffer: CVPixelBuffer) {
        FaceRecognitionService.shared.generateEmbedding(from: buffer) { [weak self] currentEmbedding in
            guard let self = self, let currentEmbedding = currentEmbedding else {
                self?.handleFailure(message: "Failed to read face features.")
                return
            }
            
            // Get enrolled embedding
            guard let enrolledEmbedding = KeychainManager.shared.getEmbedding() else {
                self.handleFailure(message: "No enrolled face found. Please enroll first.")
                return
            }
            
            let similarity = FaceRecognitionService.shared.computeCosineSimilarity(embeddingA: enrolledEmbedding, embeddingB: currentEmbedding)
            
            print("Auth Similarity: \(similarity)")
            
            if similarity >= FaceRecognitionService.shared.similarityThreshold {
                self.handleSuccess()
            } else {
                self.handleFailure(message: "Face not recognized.")
            }
        }
    }
    
    private func handleSuccess() {
        authState = .success
        statusMessage = "Match found!"
        
        // Delay slightly so the user sees the success state before closing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.stop()
            self.onAuthResult?(true)
        }
    }
    
    private func handleFailure(message: String) {
        authState = .failure
        statusMessage = message
        
        // In a real app, we might allow retries.
        // For now, delay and then fail, blocking the app.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.stop()
            self.onAuthResult?(false)
        }
    }
}
