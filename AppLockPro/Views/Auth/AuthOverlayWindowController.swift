import SwiftUI
import AppKit

/// A window controller that presents a full-screen or prominent overlay for authentication.
class AuthOverlayWindowController: NSWindowController {
    static let shared = AuthOverlayWindowController()
    
    private var completion: ((Bool) -> Void)?
    
    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 450),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating // Keep it above other normal windows
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(for appName: String, completion: @escaping (Bool) -> Void) {
        // Cancel any active session before starting a new one
        if let existingCompletion = self.completion {
            existingCompletion(false)
        }
        
        self.completion = completion
        
        let overlayView = AuthOverlayView(appName: appName) { [weak self] success in
            self?.closeWindow(success: success)
        }
        
        // Use .id to force SwiftUI to completely recreate the view and its @StateObject 
        // if the window is reused for a different appName.
        let hostingController = NSHostingController(rootView: AnyView(overlayView.id(UUID())))
        window?.contentViewController = hostingController
        
        // Ensure we activate our app so the window shows up
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.center()
    }
    
    private func closeWindow(success: Bool) {
        window?.orderOut(nil)
        completion?(success)
        completion = nil
    }
}

/// The SwiftUI view presented inside the overlay.
struct AuthOverlayView: View {
    let appName: String
    let onComplete: (Bool) -> Void
    
    @StateObject private var viewModel = AuthOverlayViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                if viewModel.authState == .success {
                    Image(systemName: "faceid")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                } else if viewModel.authState == .failure {
                    Image(systemName: "xmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.red)
                } else {
                    CameraPreviewView(session: viewModel.cameraService.captureSession)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.accentColor, lineWidth: 2)
                        )
                }
            }
            .frame(width: 120, height: 120)
            
            VStack(spacing: 8) {
                Text("FaceLock Pro")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("\(appName) is locked.")
                    .font(.title2.bold())
            }
            
            Text(viewModel.statusMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(viewModel.authState == .failure ? .red : .primary)
            
            Spacer()
        }
        .padding(40)
        .onAppear {
            viewModel.onAuthResult = onComplete
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
        .frame(width: 400, height: 450)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).ignoresSafeArea())
        .cornerRadius(16)
        // Add a subtle border or shadow for depth
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

/// Wrapper for NSVisualEffectView to get the frosted glass look
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
