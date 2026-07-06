import SwiftUI
import AVFoundation

class PreviewNSView: NSView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }
}

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    
    func makeNSView(context: Context) -> PreviewNSView {
        let view = PreviewNSView()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        view.layer = previewLayer
        view.wantsLayer = true
        view.previewLayer = previewLayer
        
        return view
    }
    
    func updateNSView(_ nsView: PreviewNSView, context: Context) {
        if let layer = nsView.previewLayer {
            layer.session = session
        }
    }
}
