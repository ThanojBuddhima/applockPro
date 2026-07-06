import SwiftUI

/// The unlock dialog displayed when a protected application is launched.
/// In later milestones, this will be shown as a floating NSPanel above all windows.
struct UnlockDialogView: View {
    let appName: String
    let appBundleID: String

    @State private var authState: AuthState = .authenticating
    @State private var selectedMethod: AuthMethod = .faceUnlock
    @State private var pinEntry: String = ""
    @State private var failedAttempts: Int = 0

    enum AuthState {
        case authenticating
        case success
        case failure(String)
        case locked
    }

    var body: some View {
        VStack(spacing: 24) {
            // App info
            HStack(spacing: 12) {
                Image(systemName: "app.fill")
                    .font(.title)
                    .foregroundStyle(.tint)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading) {
                    Text(appName)
                        .font(.title2.bold())
                    Text("is requesting authentication")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Auth content based on method
            Group {
                switch selectedMethod {
                case .faceUnlock:
                    faceUnlockContent
                case .touchID:
                    touchIDContent
                case .password:
                    passwordContent
                case .pin:
                    pinContent
                }
            }
            .frame(minHeight: 200)

            Divider()

            // Method switcher
            HStack(spacing: 16) {
                Text("Use another method:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(AuthMethod.allCases) { method in
                    if method != selectedMethod {
                        Button {
                            withAnimation { selectedMethod = method }
                        } label: {
                            Label(method.rawValue, systemImage: method.icon)
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(30)
        .frame(width: 450)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Auth Method Views

    private var faceUnlockContent: some View {
        VStack(spacing: 16) {
            // Camera preview placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(.black)
                .frame(width: 200, height: 150)
                .overlay {
                    VStack {
                        Image(systemName: "faceid")
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Camera Preview")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

            Text("Looking for your face...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView()
        }
    }

    private var touchIDContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "touchid")
                .font(.system(size: 64))
                .foregroundStyle(.pink)
                .symbolEffect(.pulse, options: .repeating)

            Text("Place your finger on Touch ID")
                .font(.headline)

            Button("Use Touch ID") {
                print("[AppLockPro] Touch ID authentication requested")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var passwordContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Enter your macOS password")
                .font(.headline)

            Button("Authenticate with macOS") {
                print("[AppLockPro] macOS password authentication requested")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var pinContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "number.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple)

            Text("Enter your PIN")
                .font(.headline)

            SecureField("PIN", text: $pinEntry)
                .textFieldStyle(.roundedBorder)
                .frame(width: 150)
                .multilineTextAlignment(.center)

            Button("Verify PIN") {
                print("[AppLockPro] PIN verification requested: \(pinEntry)")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    UnlockDialogView(
        appName: "Safari",
        appBundleID: "com.apple.Safari"
    )
    .frame(width: 500, height: 500)
}
