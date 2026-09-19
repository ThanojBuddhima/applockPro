import SwiftUI

/// Compact Dynamic Island–style unlock UI that expands from the Mac notch.
struct AuthNotchView: View {
    let appName: String
    let collapsedSize: CGSize
    let expandedSize: CGSize
    let onComplete: (Bool) -> Void

    @StateObject private var viewModel = AuthOverlayViewModel()
    @State private var isExpanded = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            island
                .frame(width: islandWidth, height: islandHeight)
                .offset(x: shakeOffset)
        }
        .frame(width: expandedSize.width, height: expandedSize.height, alignment: .top)
        .onAppear {
            viewModel.onAuthResult = onComplete
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                isExpanded = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                viewModel.start()
            }
        }
        .onDisappear {
            viewModel.stop()
        }
        .onChange(of: viewModel.authState) { _, newState in
            switch newState {
            case .success:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        isExpanded = false
                    }
                }
            case .failure:
                performShake()
            default:
                break
            }
        }
    }

    private var islandWidth: CGFloat {
        isExpanded ? expandedSize.width : collapsedSize.width
    }

    private var islandHeight: CGFloat {
        isExpanded ? expandedSize.height : collapsedSize.height
    }

    private var island: some View {
        HStack(spacing: 12) {
            if isExpanded {
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(iconColor)
                    .symbolEffect(
                        .pulse,
                        options: .repeating,
                        isActive: viewModel.authState == .scanning || viewModel.authState == .verifying
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(appName) is locked")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(viewModel.statusMessage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(statusColor)
                        .lineLimit(1)
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, isExpanded ? 18 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Color.white.opacity(isExpanded ? 0.12 : 0), lineWidth: 1)
        }
    }

    private var iconName: String {
        switch viewModel.authState {
        case .success:
            return "faceid"
        case .failure:
            return "xmark.circle.fill"
        default:
            return "faceid"
        }
    }

    private var iconColor: Color {
        switch viewModel.authState {
        case .success:
            return .green
        case .failure:
            return .red
        default:
            return .white
        }
    }

    private var statusColor: Color {
        switch viewModel.authState {
        case .success:
            return .green.opacity(0.9)
        case .failure:
            return .red.opacity(0.95)
        default:
            return .white.opacity(0.65)
        }
    }

    private func performShake() {
        Task { @MainActor in
            let offsets: [CGFloat] = [-8, 8, -6, 6, -3, 3, 0]
            for offset in offsets {
                withAnimation(.linear(duration: 0.05)) {
                    shakeOffset = offset
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }
}

#Preview {
    AuthNotchView(
        appName: "Safari",
        collapsedSize: CGSize(width: 185, height: 32),
        expandedSize: CGSize(width: 340, height: 120),
        onComplete: { _ in }
    )
    .frame(width: 400, height: 200)
    .background(Color.gray)
}
