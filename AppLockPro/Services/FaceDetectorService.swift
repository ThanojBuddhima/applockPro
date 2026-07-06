import Vision
import CoreMedia
import Combine
import OSLog

struct FaceDetectionResult {
    let boundingBox: CGRect // Normalized [0, 1] coordinates, relative to bottom-left
    let quality: Float // 0.0 to 1.0
    let pixelBuffer: CVPixelBuffer?
}

final class FaceDetectorService: ObservableObject {
    private let logger = Logger(subsystem: "com.applockpro.facelockpro", category: "FaceDetectorService")
    
    @Published var currentFace: FaceDetectionResult?
    @Published var instruction: String = "Position your face in the center"
    
    private let detectionQueue = DispatchQueue(label: "com.applockpro.facelockpro.faceDetectionQueue", qos: .userInteractive)
    
    private var cancellables = Set<AnyCancellable>()
    
    private var frameCount = 0
    
    func startProcessing(framePublisher: PassthroughSubject<CMSampleBuffer, Never>) {
        framePublisher
            .receive(on: detectionQueue)
            .sink { [weak self] sampleBuffer in
                self?.process(sampleBuffer: sampleBuffer)
            }
            .store(in: &cancellables)
    }
    
    func stopProcessing() {
        cancellables.removeAll()
        DispatchQueue.main.async {
            self.currentFace = nil
        }
    }
    
    private func process(sampleBuffer: CMSampleBuffer) {
        // Process 1 out of every 3 frames (~10 FPS)
        frameCount += 1
        if frameCount % 3 != 0 { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        let faceRequest = VNDetectFaceRectanglesRequest()
        let qualityRequest = VNDetectFaceCaptureQualityRequest()
        
        do {
            try requestHandler.perform([faceRequest, qualityRequest])
            
            guard let faceObs = faceRequest.results?.first,
                  let qualityObs = qualityRequest.results?.first else {
                
                DispatchQueue.main.async {
                    self.currentFace = nil
                    self.instruction = "No face detected"
                }
                return
            }
            
            let quality = qualityObs.faceCaptureQuality ?? 0.0
            let result = FaceDetectionResult(boundingBox: faceObs.boundingBox, quality: quality, pixelBuffer: pixelBuffer)
            
            DispatchQueue.main.async {
                self.currentFace = result
                
                if quality < 0.3 {
                    self.instruction = "Improve lighting or hold still"
                } else if faceObs.boundingBox.width < 0.2 {
                    self.instruction = "Move closer"
                } else {
                    self.instruction = "Perfect! Hold still."
                }
            }
        } catch {
            logger.error("Failed to perform Vision requests: \(error.localizedDescription)")
        }
    }
}
