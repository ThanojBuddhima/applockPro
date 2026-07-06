import AVFoundation
import Combine
import OSLog

final class CameraService: NSObject, ObservableObject {
    private let logger = Logger(subsystem: "com.applockpro.facelockpro", category: "CameraService")
    
    let captureSession = AVCaptureSession()
    
    @Published var isRunning = false
    @Published var error: Error?
    
    // Use a PassthroughSubject to emit frames to the FaceDetectorService
    let framePublisher = PassthroughSubject<CMSampleBuffer, Never>()
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.applockpro.facelockpro.cameraQueue", qos: .userInteractive)
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            
            self.captureSession.sessionPreset = .vga640x480 // Lower resolution is better for ML processing speed
            
            // Setup Input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                self.logger.error("Failed to get front camera or create input")
                self.captureSession.commitConfiguration()
                return
            }
            
            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
            }
            
            // Setup Output
            self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }
            
            // Make sure the connection is in the correct orientation (usually mirrors for front camera)
            if let connection = self.videoOutput.connection(with: .video) {
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true // Mirror the front camera
                }
            }
            
            self.captureSession.commitConfiguration()
            self.logger.info("Camera session configured successfully.")
        }
    }
    
    func start() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isRunning = true
                }
                self.logger.info("Camera session started.")
            }
        }
    }
    
    func stop() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isRunning = false
                }
                self.logger.info("Camera session stopped.")
            }
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        framePublisher.send(sampleBuffer)
    }
}
