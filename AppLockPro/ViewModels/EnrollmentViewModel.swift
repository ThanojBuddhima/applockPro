import Foundation
import Combine
import SwiftUI

final class EnrollmentViewModel: ObservableObject {
    @Published var captureProgress: Double = 0
    @Published var capturedCount: Int = 0
    @Published var currentInstruction: String = "Position your face in the center"
    @Published var isFinishedCapturing: Bool = false
    
    let totalCaptures = Constants.FaceRecognition.enrollmentImageCount
    
    let cameraService = CameraService()
    let faceDetector = FaceDetectorService()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to face detection updates
        faceDetector.$currentFace
            .receive(on: RunLoop.main)
            .sink { [weak self] faceResult in
                self?.handleFaceResult(faceResult)
            }
            .store(in: &cancellables)
            
        faceDetector.$instruction
            .receive(on: RunLoop.main)
            .sink { [weak self] instruction in
                // Only override instruction if we are still capturing
                guard let self = self, !self.isFinishedCapturing else { return }
                self.currentInstruction = instruction
            }
            .store(in: &cancellables)
    }
    
    func startCamera() {
        capturedCount = 0
        captureProgress = 0
        isFinishedCapturing = false
        
        cameraService.start()
        faceDetector.startProcessing(framePublisher: cameraService.framePublisher)
    }
    
    func stopCamera() {
        cameraService.stop()
        faceDetector.stopProcessing()
    }
    
    private func handleFaceResult(_ result: FaceDetectionResult?) {
        guard !isFinishedCapturing, let result = result else { return }
        
        // If quality is good enough, we "capture" a frame (simulate saving it for processing)
        if result.quality > 0.4 {
            capturedCount += 1
            captureProgress = Double(capturedCount) / Double(totalCaptures)
            
            if capturedCount >= totalCaptures {
                isFinishedCapturing = true
                currentInstruction = "Processing..."
                stopCamera()
            }
        }
    }
    
    func saveDummyEmbedding() {
        // In Milestone 3, we will use ArcFace to generate the actual embeddings from the captured frames.
        // For now, we simulate a delay and saving to Keychain.
    }
}
