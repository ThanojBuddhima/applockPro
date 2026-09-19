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
    @Published var statusMessage: String = "Looking for you…"
    
    let cameraService = CameraService()
    let faceDetector = FaceDetectorService()
    
    private var cancellables = Set<AnyCancellable>()
    private var isVerifying = false
    private var framesSinceStart = 0
    private let warmupFrameCount = 10 // Skip first ~10 frames to let camera warm up
    
    var onAuthResult: ((Bool) -> Void)?
    
    private var sessionFailures = 0
    private var maxAttempts: Int {
        let saved = UserDefaults.standard.integer(forKey: "maxAttempts")
        return saved > 0 ? saved : 3
    }
    
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
        sessionFailures = 0
        framesSinceStart = 0
        authState = .scanning
        statusMessage = "Looking for you…"
        cameraService.start()
        faceDetector.startProcessing(framePublisher: cameraService.framePublisher)
    }
    
    func stop() {
        cameraService.stop()
        faceDetector.stopProcessing()
    }
    
    private func handleFaceResult(_ result: FaceDetectionResult?) {
        guard !isVerifying, authState == .scanning, let result = result else { return }
        
        // Camera warm-up: skip early frames that may produce blurry/overexposed images
        framesSinceStart += 1
        if framesSinceStart < warmupFrameCount {
            statusMessage = "Looking for you…"
            return
        }
        
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
                self?.handleFailure(message: "Can't read face")
                return
            }
            
            // Get enrolled embedding
            guard let enrolledEmbedding = KeychainManager.shared.getEmbedding() else {
                self.handleFailure(message: "No enrolled face")
                return
            }
            
            let similarity = FaceRecognitionService.shared.computeCosineSimilarity(embeddingA: enrolledEmbedding, embeddingB: currentEmbedding)
            
            NSLog("Auth Similarity: %f", similarity)
            self.logToFile("Auth Similarity: \(similarity) vs threshold: \(FaceRecognitionService.shared.similarityThreshold)")
            
            if similarity >= FaceRecognitionService.shared.similarityThreshold {
                self.handleSuccess()
            } else {
                self.handleFailure(message: "Not recognized")
            }
        }
    }
    
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
    
    private func handleSuccess() {
        StatsManager.shared.recordSuccess()
        SessionManager.shared.activateSession()
        
        authState = .success
        statusMessage = "Unlocked"
        stop()

        // Delay so the island can collapse back into the notch before dismissing.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            self.onAuthResult?(true)
        }
    }
    
    private func handleFailure(message: String) {
        logToFile("handleFailure called: \(message)")
        StatsManager.shared.recordFailure()
        sessionFailures += 1
        
        authState = .failure
        statusMessage = message
        
        // Delay slightly so the user sees the failure, then prompt fallback auth
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.stop()
            
            if self.sessionFailures >= self.maxAttempts {
                self.statusMessage = "Use password"
                // Force system auth immediately
                SystemAuthService.shared.authenticate(reason: "Face ID failed too many times. Please use Touch ID or your Mac password to unlock.") { [weak self] success in
                    if success {
                        self?.handleSuccess()
                    } else {
                        self?.statusMessage = "Failed"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self?.onAuthResult?(false)
                        }
                    }
                }
                return
            }
            
            self.statusMessage = "Use Touch ID"
            
            SystemAuthService.shared.authenticate(reason: "Face ID failed. Please use Touch ID or your Mac password to unlock.") { [weak self] success in
                if success {
                    self?.handleSuccess()
                } else {
                    self?.statusMessage = "Failed"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.onAuthResult?(false)
                    }
                }
            }
        }
    }
}
