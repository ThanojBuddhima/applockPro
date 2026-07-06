import SwiftUI

/// Displays the authentication activity history with filtering.
struct ActivityHistoryView: View {
    @State private var selectedFilter: ActivityLogEntry.EventType? = nil
    @State private var searchText = ""
    @State private var logEntries: [ActivityLogEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity History")
                        .font(.largeTitle.bold())
                    Text("View all authentication events and app access logs")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    // Future: clear logs
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            .padding(30)

            Divider()

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: selectedFilter == nil) {
                        selectedFilter = nil
                    }

                    ForEach(ActivityLogEntry.EventType.allCases, id: \.rawValue) { eventType in
                        FilterChip(
                            title: eventType.rawValue,
                            isSelected: selectedFilter == eventType
                        ) {
                            selectedFilter = eventType
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
            }

            Divider()

            // Log entries
            if logEntries.isEmpty {
                emptyState
            } else {
                List(logEntries) { entry in
                    logEntryRow(entry)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Activity Yet")
                .font(.title2.bold())

            Text("Authentication events will appear here once you start\nusing FaceLock Pro to protect your applications.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func logEntryRow(_ entry: ActivityLogEntry) -> some View {
        HStack(spacing: 16) {
            Image(systemName: entry.eventType.icon)
                .font(.title3)
                .foregroundStyle(colorForEvent(entry.eventType))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.eventType.rawValue)
                    .font(.headline)
                if let appName = entry.appName {
                    Text(appName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let confidence = entry.confidenceScore {
                Text(String(format: "%.0f%%", confidence * 100))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(entry.timestamp, style: .relative)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func colorForEvent(_ eventType: ActivityLogEntry.EventType) -> Color {
        switch eventType.color {
        case "green":  return .green
        case "red":    return .red
        case "blue":   return .blue
        default:       return .gray
        }
    }
}

/// A filter chip button for the activity log.
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.15),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ActivityHistoryView()
        .frame(width: 750, height: 600)
}
