import SwiftUI

/// Notch unlock overlay: black housing hanging from the camera notch with a Face ID glyph.
struct AuthNotchView: View {
    let appName: String
    let animationEnabled: Bool
    let collapsedSize: CGSize
    let expandedSize: CGSize
    let onComplete: (Bool) -> Void

    @StateObject private var viewModel = AuthOverlayViewModel()
    @State private var isExpanded = false
    @State private var shakeOffset: CGFloat = 0
    @State private var isPulsing = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            island
                .frame(width: islandWidth, height: islandHeight)
                .offset(x: shakeOffset)
        }
        .frame(width: expandedSize.width, height: expandedSize.height, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(appName) is locked")
        .accessibilityValue(viewModel.statusMessage)
        .onAppear {
            viewModel.onAuthResult = onComplete
            if animationEnabled {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                    isExpanded = true
                }
            } else {
                isExpanded = true
            }
            isPulsing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + (animationEnabled ? 0.12 : 0)) {
                viewModel.start()
            }
        }
        .onDisappear {
            viewModel.stop()
        }
        .onChange(of: viewModel.authState) { _, newState in
            switch newState {
            case .success:
                isPulsing = false
                guard animationEnabled else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        isExpanded = false
                    }
                }
            case .failure:
                isPulsing = false
                performShake()
            default:
                isPulsing = true
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
        ZStack {
            if isExpanded {
                FaceIDGlyph(color: glyphColor)
                    .frame(width: 64, height: 64)
                    .scaleEffect(isPulsing ? 1.08 : 1.0)
                    .animation(
                        isPulsing
                            ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                            : .easeOut(duration: 0.2),
                        value: isPulsing
                    )
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.black)
        .clipShape(islandShape)
    }

    private var islandShape: UnevenRoundedRectangle {
        let collapsedBottom = collapsedSize.height / 2
        return UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: isExpanded ? 36 : collapsedBottom,
            bottomTrailingRadius: isExpanded ? 36 : collapsedBottom,
            topTrailingRadius: 0,
            style: .continuous
        )
    }

    private var glyphColor: Color {
        switch viewModel.authState {
        case .success:
            return .green
        case .failure:
            return .red
        default:
            return UnlockPalette.scanCyan
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
        animationEnabled: true,
        collapsedSize: CGSize(width: 185, height: 32),
        expandedSize: CGSize(width: 213, height: 132),
        onComplete: { _ in }
    )
    .frame(width: 240, height: 160)
    .background(Color.gray)
}
