import SwiftUI

/// The main settings view with tabbed sections.
struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case security = "Security"
        case camera = "Camera"
        case privacy = "Privacy"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general:  return "gearshape"
            case .security: return "lock.shield"
            case .camera:   return "camera"
            case .privacy:  return "hand.raised"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.largeTitle.bold())
                Spacer()
            }
            .padding(30)

            Divider()

            // Tab bar
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab
                                ? Color.accentColor.opacity(0.1)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 12)

            Divider()

            // Tab content
            ScrollView {
                Group {
                    switch selectedTab {
                    case .general:  GeneralSettingsSection()
                    case .security: SecuritySettingsSection()
                    case .camera:   CameraSettingsSection()
                    case .privacy:  PrivacySettingsSection()
                    }
                }
                .padding(30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Settings Sections

struct GeneralSettingsSection: View {
    @State private var launchAtStartup = false
    @State private var startMinimized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsGroup(title: "Startup") {
                Toggle("Launch FaceLock Pro at login", isOn: $launchAtStartup)
                Toggle("Start minimized to menu bar", isOn: $startMinimized)
            }

            settingsGroup(title: "Appearance") {
                HStack {
                    Text("Theme")
                    Spacer()
                    Picker("", selection: .constant("system")) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                }
            }
        }
    }
}

struct SecuritySettingsSection: View {
    @State private var faceUnlock = true
    @State private var touchID = true
    @State private var macPassword = true
    @State private var pin = false
    @State private var confidenceThreshold: Double = 0.55
    @State private var maxAttempts = 5
    @State private var lockAfterSleep = true
    @State private var sessionTimeout: AppSettings.SessionTimeout = .thirtyMinutes

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsGroup(title: "Authentication Methods") {
                Toggle("Face Unlock", isOn: $faceUnlock)
                Toggle("Touch ID", isOn: $touchID)
                Toggle("macOS Password", isOn: $macPassword)
                Toggle("Application PIN", isOn: $pin)
            }

            settingsGroup(title: "Face Recognition") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Confidence Threshold")
                        Spacer()
                        Text(String(format: "%.0f%%", confidenceThreshold * 100))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $confidenceThreshold, in: 0.3...0.9, step: 0.05)
                    Text("Higher values are more secure but may reject valid users.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            settingsGroup(title: "Auto Lock") {
                Toggle("Lock after sleep", isOn: $lockAfterSleep)
                HStack {
                    Text("Session timeout")
                    Spacer()
                    Picker("", selection: $sessionTimeout) {
                        ForEach(AppSettings.SessionTimeout.allCases) { timeout in
                            Text(timeout.rawValue).tag(timeout)
                        }
                    }
                    .frame(width: 200)
                }
            }

            settingsGroup(title: "Failed Attempts") {
                Stepper("Maximum attempts: \(maxAttempts)", value: $maxAttempts, in: 3...10)
            }
        }
    }
}

struct CameraSettingsSection: View {
    @State private var livenessEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsGroup(title: "Camera") {
                HStack {
                    Text("Selected Camera")
                    Spacer()
                    Picker("", selection: .constant("default")) {
                        Text("FaceTime HD Camera").tag("default")
                    }
                    .frame(width: 250)
                }
            }

            settingsGroup(title: "Liveness Detection") {
                Toggle("Enable liveness detection", isOn: $livenessEnabled)
                Text("Requires you to blink or move your head to prevent spoofing attacks.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct PrivacySettingsSection: View {
    @State private var showingClearConfirmation = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsGroup(title: "Data Management") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Clear Activity Logs")
                        Text("Remove all authentication history")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Clear Logs") {
                        showingClearConfirmation = true
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Delete Face Data")
                        Text("Remove your enrolled face embeddings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Delete") {
                        showingDeleteConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }

            settingsGroup(title: "Export / Import") {
                HStack {
                    Text("Export Settings")
                    Spacer()
                    Button("Export") {}
                        .buttonStyle(.bordered)
                }
                HStack {
                    Text("Import Settings")
                    Spacer()
                    Button("Import") {}
                        .buttonStyle(.bordered)
                }
            }
        }
        .alert("Clear Activity Logs?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {}
        } message: {
            Text("This will permanently delete all authentication history. This action cannot be undone.")
        }
        .alert("Delete Face Data?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {}
        } message: {
            Text("This will remove your enrolled face data. You will need to re-enroll to use Face Unlock.")
        }
    }
}

// MARK: - Helper

/// Wraps settings rows in a titled group card.
func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 16) {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)

        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    SettingsView()
        .frame(width: 750, height: 600)
}
