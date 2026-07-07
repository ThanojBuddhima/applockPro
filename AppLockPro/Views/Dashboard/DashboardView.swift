import SwiftUI

/// Main dashboard showing an overview of protection status and quick actions.
struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    // Placeholder stats for the UI skeleton
    @State private var protectedAppsCount = 0
    @State private var authSuccessToday = 0
    @State private var authFailuresToday = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                // Status cards
                statusCardsSection

                // Quick actions
                quickActionsSection

                // Recent activity placeholder
                recentActivitySection
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard")
                        .font(.largeTitle.bold())

                    Text("Welcome back. Your apps are protected.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Enrollment status badge
                StatusBadge(
                    title: appState.isEnrolled ? "Face Enrolled" : "Not Enrolled",
                    icon: appState.isEnrolled ? "checkmark.shield.fill" : "exclamationmark.triangle.fill",
                    color: appState.isEnrolled ? .green : .orange
                )
            }
        }
    }

    private var statusCardsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Protected Apps",
                value: "\(protectedAppsCount)",
                icon: "lock.shield.fill",
                color: .blue
            )
            StatCard(
                title: "Unlocks Today",
                value: "\(authSuccessToday)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            StatCard(
                title: "Failed Attempts",
                value: "\(authFailuresToday)",
                icon: "xmark.circle.fill",
                color: authFailuresToday > 0 ? .red : .gray
            )
            StatCard(
                title: "Session Status",
                value: "Active",
                icon: "bolt.shield.fill",
                color: .purple
            )
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                QuickActionButton(title: "Add App", icon: "plus.app", color: .blue) {
                    appState.selectedNavItem = .protectedApps
                }
                QuickActionButton(title: "Re-Enroll Face", icon: "faceid", color: .orange) {
                    appState.selectedNavItem = .enrollment
                }
                QuickActionButton(title: "Settings", icon: "gearshape", color: .gray) {
                    appState.selectedNavItem = .settings
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)

                Spacer()
            }

            // Placeholder
            VStack(spacing: 8) {
                Text("No recent activity")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Subviews

/// A statistics card for the dashboard.
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// A quick action button for the dashboard.
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

/// A status badge (e.g., "Face Enrolled" / "Not Enrolled").
struct StatusBadge: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
            Text(title)
                .font(.subheadline.bold())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1), in: Capsule())
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
        .frame(width: 750, height: 600)
}
