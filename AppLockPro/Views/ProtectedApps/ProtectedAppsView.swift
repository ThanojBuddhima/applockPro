import SwiftUI

/// View for managing which applications are protected by FaceLock Pro.
struct ProtectedAppsView: View {
    @State private var searchText = ""
    @State private var showingAppPicker = false
    @State private var protectedApps: [ProtectedApp] = []

    var filteredApps: [ProtectedApp] {
        if searchText.isEmpty {
            return protectedApps
        }
        return protectedApps.filter {
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
                    Text("\(protectedApps.count) app\(protectedApps.count == 1 ? "" : "s") protected")
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
            AppPickerView(protectedApps: $protectedApps)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Protected Apps")
                .font(.title2.bold())

            Text("Add applications to protect them with FaceLock Pro.\nProtected apps will require authentication before opening.")
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

            Toggle("Protected", isOn: .constant(app.isProtected))
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }

    private func removeApps(at offsets: IndexSet) {
        protectedApps.remove(atOffsets: offsets)
    }
}

/// Sheet view for picking installed apps to protect.
struct AppPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var protectedApps: [ProtectedApp]
    @State private var searchText = ""

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

            // Placeholder list
            VStack(spacing: 12) {
                Text("Application list will be populated from /Applications")
                    .foregroundStyle(.secondary)
                Text("Coming in Milestone 4")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 500, height: 500)
    }
}

#Preview {
    ProtectedAppsView()
        .frame(width: 750, height: 600)
}
