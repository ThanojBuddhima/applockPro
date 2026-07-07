import SwiftUI
import AVFoundation
import ApplicationServices

/// The welcome / onboarding screen shown on first launch.
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep: OnboardingStep = .welcome
    @State private var cameraGranted = false
    @State private var accessibilityGranted = false
    
    // Timer to automatically poll permission state
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case enrollment
        case permissions
        case complete
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                    Capsule()
                        .fill(step.rawValue <= currentStep.rawValue
                              ? Color.accentColor
                              : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            Spacer()

            // Step content
            Group {
                switch currentStep {
                case .welcome:
                    welcomeContent
                case .enrollment:
                    enrollmentContent
                case .permissions:
                    permissionsContent
                case .complete:
                    completeContent
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Spacer()

            // Navigation buttons
            HStack {
                if currentStep != .welcome {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                                currentStep = prev
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep == .complete {
                    Button("Get Started") {
                        withAnimation {
                            appState.onboardingCompleted = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Continue") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                                currentStep = next
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(
                        (currentStep == .permissions && (!cameraGranted || !accessibilityGranted)) ||
                        (currentStep == .enrollment && !appState.isEnrolled)
                    )
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Step Content

    private var welcomeContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "faceid")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, options: .repeating)

            Text("Welcome to AppLock Pro")
                .font(.largeTitle.bold())

            Text("Protect your applications with AI-powered facial recognition.\nFast, secure, and completely offline.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            HStack(spacing: 30) {
                featureItem(icon: "lock.shield.fill", title: "App Protection", subtitle: "Lock any app")
                featureItem(icon: "face.smiling.fill", title: "Face Unlock", subtitle: "Instant access")
                featureItem(icon: "network.slash", title: "100% Offline", subtitle: "Private by design")
            }
            .padding(.top, 20)
        }
    }

    private var permissionsContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Permissions Required")
                .font(.largeTitle.bold())

            Text("AppLock Pro needs the following permissions to protect your apps.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            VStack(alignment: .leading, spacing: 16) {
                permissionRow(
                    icon: "camera.fill",
                    title: "Camera Access",
                    subtitle: "Required for facial recognition",
                    granted: cameraGranted
                ) {
                    requestCamera()
                }
                
                permissionRow(
                    icon: "universalaccess",
                    title: "Accessibility",
                    subtitle: "Required to monitor app launches",
                    granted: accessibilityGranted
                ) {
                    requestAccessibility()
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
            
            if !accessibilityGranted {
                Text("Clicking 'Grant Access' for Accessibility will open System Settings. Check the box for AppLock Pro, then return here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .onAppear {
            checkPermissions()
        }
        .onReceive(timer) { _ in
            if currentStep == .permissions {
                checkPermissions()
            }
        }
    }

    private var enrollmentContent: some View {
        EnrollmentWizardView()
    }

    private var completeContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.largeTitle.bold())

            Text("AppLock Pro is ready to protect your applications.\nYou can configure everything from the dashboard.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)
        }
    }

    // MARK: - Helper Views

    private func featureItem(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.tint)
                .frame(width: 50, height: 50)
                .background(.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func permissionRow(icon: String, title: String, subtitle: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            } else {
                Button("Grant Access") {
                    action()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func checkPermissions() {
        cameraGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        accessibilityGranted = AXIsProcessTrusted()
    }
    
    private func requestCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraGranted = granted
            }
        }
    }
    
    private func requestAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        self.accessibilityGranted = accessEnabled
    }

    private func enrollmentStep(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.tint, in: Circle())

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
