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
        if result.quality > 0.4, let _ = result.pixelBuffer {
            isVerifying = true
            authState = .verifying
            statusMessage = "Verifying..."
            
            // Stop scanning to prevent multiple verifications
            faceDetector.stopProcessing()
            
            verifyFace(result: result)
        }
    }
    
    private func verifyFace(result: FaceDetectionResult) {
        guard let buffer = result.pixelBuffer else { return }
        FaceRecognitionService.shared.generateEmbedding(from: buffer, faceRect: result.boundingBox) { [weak self] currentEmbedding in
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
            
            NSLog("Auth Similarity: %f", similarity)
            
            if similarity >= FaceRecognitionService.shared.similarityThreshold {
                self.handleSuccess()
            } else {
                let formattedSim = String(format: "%.2f", similarity)
                self.handleFailure(message: "Face not recognized (Score: \(formattedSim))")
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
        
        // Delay slightly so the user sees the failure, then prompt fallback auth
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.stop()
            self.statusMessage = "Use Touch ID or Password..."
            
            SystemAuthService.shared.authenticate(reason: "Face ID failed. Please use Touch ID or your Mac password to unlock.") { [weak self] success in
                if success {
                    self?.handleSuccess()
                } else {
                    self?.statusMessage = "Authentication Failed."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.onAuthResult?(false)
                    }
                }
            }
        }
    }
}
