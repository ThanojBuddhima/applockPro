import SwiftUI

/// View for managing which applications are protected by AppLock Pro.
struct ProtectedAppsView: View {
    @State private var searchText = ""
    @State private var showingAppPicker = false
    @ObservedObject private var appManager = AppManager.shared

    var filteredApps: [ProtectedApp] {
        if searchText.isEmpty {
            return appManager.protectedApps
        }
        return appManager.protectedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protected Apps")
                        .font(.largeTitle.bold())
                    Text("\(appManager.protectedApps.count) app\(appManager.protectedApps.count == 1 ? "" : "s") protected")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingAppPicker = true
                } label: {
                    Label("Add App", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(30)

            Divider()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search protected apps...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 30)
            .padding(.vertical, 12)

            // App list
            if filteredApps.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredApps) { app in
                        protectedAppRow(app)
                    }
                    .onDelete(perform: removeApps)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Protected Apps")
                .font(.title2.bold())

            Text("Add applications to protect them with AppLock Pro.\nProtected apps will require authentication before opening.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button {
                showingAppPicker = true
            } label: {
                Label("Add Your First App", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func protectedAppRow(_ app: ProtectedApp) -> some View {
        HStack(spacing: 16) {
            // App icon placeholder
            Image(systemName: "app.fill")
                .font(.title)
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.headline)
                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            let isProtectedBinding = Binding<Bool>(
                get: {
                    if let index = appManager.protectedApps.firstIndex(where: { $0.id == app.id }) {
                        return appManager.protectedApps[index].isProtected
                    }
                    return false
                },
                set: { newValue in
                    if let index = appManager.protectedApps.firstIndex(where: { $0.id == app.id }) {
                        appManager.protectedApps[index].isProtected = newValue
                    }
                }
            )

            Toggle("Protected", isOn: isProtectedBinding)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }

    private func removeApps(at offsets: IndexSet) {
        let appsToRemove = offsets.map { filteredApps[$0] }
        for app in appsToRemove {
            appManager.removeApp(bundleIdentifier: app.bundleIdentifier)
        }
    }
}

/// Sheet view for picking installed apps to protect.
struct AppPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appManager = AppManager.shared
    @State private var searchText = ""
    @State private var installedApps: [InstalledApp] = []
    @State private var isLoading = true
    
    var filteredApps: [InstalledApp] {
        if searchText.isEmpty {
            return installedApps
        }
        return installedApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Applications to Protect")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search applications...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            .padding()

            // App List
            if isLoading {
                ProgressView("Scanning for applications...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredApps.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No applications found")
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredApps) { app in
                    HStack(spacing: 12) {
                        Image(nsImage: app.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading) {
                            Text(app.name).font(.headline)
                            Text(app.path).font(.caption).foregroundStyle(.secondary).truncationMode(.middle)
                        }
                        
                        Spacer()
                        
                        let isProtected = appManager.protectedApps.contains { $0.bundleIdentifier == app.bundleIdentifier }
                        if isProtected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                        } else {
                            Button("Add") {
                                let newApp = ProtectedApp(name: app.name, bundleIdentifier: app.bundleIdentifier, path: app.path)
                                appManager.addApp(newApp)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .frame(width: 550, height: 600)
        .onAppear {
            loadApps()
        }
    }
    
    private func loadApps() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchedApps = AppListService.shared.fetchInstalledApps()
            DispatchQueue.main.async {
                self.installedApps = fetchedApps
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ProtectedAppsView()
        .frame(width: 750, height: 600)
}
