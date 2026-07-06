import SwiftUI

/// Face enrollment wizard that guides the user through setting up facial recognition.
struct EnrollmentWizardView: View {
    @EnvironmentObject var appState: AppState
    @State private var enrollmentState: EnrollmentState = .ready
    @State private var captureProgress: Double = 0
    @State private var capturedCount: Int = 0
    @State private var currentInstruction: String = "Position your face in the center"

    enum EnrollmentState {
        case ready
        case capturing
        case processing
        case complete
        case error(String)
    }

    private let totalCaptures = Constants.FaceRecognition.enrollmentImageCount

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Face Enrollment")
                        .font(.largeTitle.bold())
                    Text(appState.isEnrolled
                         ? "Re-enroll to update your face data"
                         : "Set up facial recognition for secure authentication")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(30)

            Divider()

            // Main content
            Group {
                switch enrollmentState {
                case .ready:
                    readyContent
                case .capturing:
                    capturingContent
                case .processing:
                    processingContent
                case .complete:
                    completeContent
                case .error(let message):
                    errorContent(message)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - State Content

    private var readyContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Ready to Enroll")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 12) {
                instructionRow(icon: "light.max", text: "Make sure you have good lighting")
                instructionRow(icon: "eye.fill", text: "Keep your eyes visible")
                instructionRow(icon: "arrow.left.arrow.right", text: "You'll be asked to look in different directions")
                instructionRow(icon: "lock.shield.fill", text: "Your face data is encrypted and stored locally")
            }
            .frame(maxWidth: 400)

            Button("Start Enrollment") {
                withAnimation {
                    enrollmentState = .capturing
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if appState.isEnrolled {
                Text("⚠ This will replace your current face data")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var capturingContent: some View {
        VStack(spacing: 24) {
            // Camera preview placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(.black)
                .frame(width: 320, height: 240)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Camera Preview")
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Coming in Milestone 2")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

            // Instruction
            Text(currentInstruction)
                .font(.title3.bold())
                .foregroundStyle(.tint)

            // Progress
            VStack(spacing: 8) {
                ProgressView(value: captureProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 300)

                Text("\(capturedCount) / \(totalCaptures) captures")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Cancel button
            Button("Cancel") {
                withAnimation {
                    enrollmentState = .ready
                    captureProgress = 0
                    capturedCount = 0
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private var processingContent: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)
                .padding()

            Text("Processing face data...")
                .font(.title2.bold())

            Text("Generating embeddings and encrypting your biometric data.\nThis may take a few seconds.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var completeContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Enrollment Complete!")
                .font(.title.bold())

            Text("Your face has been enrolled successfully.\nYou can now use Face Unlock to authenticate.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Done") {
                withAnimation {
                    appState.isEnrolled = true
                    enrollmentState = .ready
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            Text("Enrollment Failed")
                .font(.title.bold())

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                withAnimation {
                    enrollmentState = .ready
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: - Helper Views

    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 24)
            Text(text)
        }
    }
}

#Preview {
    EnrollmentWizardView()
        .environmentObject(AppState())
        .frame(width: 750, height: 600)
}
