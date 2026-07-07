import SwiftUI

/// About screen showing application info, version, and credits.
struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("About")
                    .font(.largeTitle.bold())
                Spacer()
            }
            .padding(30)

            Divider()

            ScrollView {
                VStack(spacing: 32) {
                    // App icon and name
                    VStack(spacing: 16) {
                        Image(systemName: "faceid")
                            .font(.system(size: 72))
                            .foregroundStyle(.tint)
                            .padding()
                            .background(.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))

                        Text("AppLock Pro")
                            .font(.title.bold())

                        Text("Version \(Constants.App.version)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Description
                    Text("AI-Powered Privacy & App Locker for macOS.\nProtect your applications with offline facial recognition.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 450)

                    Divider()
                        .frame(maxWidth: 400)

                    // Technology stack
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Technology")
                            .font(.headline)

                        HStack(spacing: 24) {
                            techBadge(name: "Swift", icon: "swift")
                            techBadge(name: "SwiftUI", icon: "rectangle.on.rectangle")
                            techBadge(name: "Core ML", icon: "brain")
                            techBadge(name: "Vision", icon: "eye.fill")
                            techBadge(name: "AVFoundation", icon: "camera.fill")
                        }
                    }

                    Divider()
                        .frame(maxWidth: 400)

                    // Links
                    VStack(spacing: 12) {
                        Text("Designed for Apple Silicon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("© 2025 AppLockPro. All rights reserved.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func techBadge(name: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)

            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AboutView()
        .frame(width: 750, height: 600)
}
