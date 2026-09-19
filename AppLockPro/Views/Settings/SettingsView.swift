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

import ServiceManagement

struct GeneralSettingsSection: View {
    @AppStorage("launchAtLogin") private var launchAtStartup = false
    @AppStorage("hideDockIcon") private var hideDockIcon = false
    @AppStorage(Constants.Defaults.unlockAnimationEnabled) private var unlockAnimationEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsGroup(title: "Startup") {
                Toggle("Launch AppLock Pro at login", isOn: $launchAtStartup)
                    .onChange(of: launchAtStartup) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Failed to update Launch at Login: \(error)")
                        }
                    }
                Toggle("Hide Dock Icon (Run in Menu Bar)", isOn: $hideDockIcon)
                    .onChange(of: hideDockIcon) { _, newValue in
                        if newValue {
                            NSApp.setActivationPolicy(.accessory)
                        } else {
                            NSApp.setActivationPolicy(.regular)
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }
            }

            settingsGroup(title: "Animation") {
                Toggle("Show animation", isOn: $unlockAnimationEnabled)
                Text("The animation that appears when unlocking")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SecuritySettingsSection: View {
    @AppStorage("faceUnlockEnabled") private var faceUnlock = true
    @AppStorage("touchIDEnabled") private var touchID = true
    @AppStorage("macPasswordEnabled") private var macPassword = true
    
    @AppStorage("maxFailedAttempts") private var maxAttempts = 5
    @AppStorage("lockAfterSleep") private var lockAfterSleep = true
    
    // For Enum in AppStorage, we must store the RawValue (String)
    @AppStorage("sessionTimeout") private var sessionTimeoutRaw = AppSettings.SessionTimeout.thirtyMinutes.rawValue
    
    private var sessionTimeout: Binding<AppSettings.SessionTimeout> {
        Binding(
            get: { AppSettings.SessionTimeout(rawValue: sessionTimeoutRaw) ?? .thirtyMinutes },
            set: { sessionTimeoutRaw = $0.rawValue }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsGroup(title: "Authentication Methods") {
                Toggle("Face Unlock", isOn: $faceUnlock)
                Toggle("Touch ID", isOn: $touchID)
                Toggle("macOS Password", isOn: $macPassword)
            }

            settingsGroup(title: "Failed Attempts") {
                Stepper("Maximum attempts: \(maxAttempts)", value: $maxAttempts, in: 3...10)
            }
        }
    }
}

import AVFoundation

struct CameraSettingsSection: View {
    @AppStorage("livenessEnabled") private var livenessEnabled = true
    @AppStorage("selectedCameraID") private var selectedCameraID = "default"
    
    @State private var availableCameras: [AVCaptureDevice] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsGroup(title: "Camera") {
                HStack {
                    Text("Selected Camera")
                    Spacer()
                    Picker("", selection: $selectedCameraID) {
                        Text("Default Camera").tag("default")
                        ForEach(availableCameras, id: \.uniqueID) { camera in
                            Text(camera.localizedName).tag(camera.uniqueID)
                        }
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
        .onAppear {
            let session = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .external],
                mediaType: .video,
                position: .unspecified
            )
            self.availableCameras = session.devices
        }
    }
}

struct PrivacySettingsSection: View {
    @EnvironmentObject var appState: AppState
    @State private var showingDeleteConfirmation = false
    @State private var showingResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsGroup(title: "Data Management") {

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
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Reset App State")
                        Text("Reset all settings and replay the welcome wizard")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Reset App") {
                        showingResetConfirmation = true
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
        .alert("Delete Face Data?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                UserDefaults.standard.removeObject(forKey: "faceEmbedding")
                UserDefaults.standard.set(false, forKey: "isEnrolled")
                withAnimation {
                    appState.isEnrolled = false
                }
            }
        } message: {
            Text("This will remove your enrolled face data. You will need to re-enroll to use Face Unlock.")
        }
        .alert("Reset App State?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Everything", role: .destructive) {
                // Clear all UserDefaults
                if let bundleID = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: bundleID)
                    UserDefaults.standard.synchronize()
                }
                // Update AppState to trigger SwiftUI to show the Welcome wizard
                withAnimation {
                    appState.isEnrolled = false
                    appState.onboardingCompleted = false
                }
            }
        } message: {
            Text("This will clear all permissions, settings, and face data, and restart the onboarding wizard.")
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
