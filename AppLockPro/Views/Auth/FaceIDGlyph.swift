import SwiftUI

/// Face ID corner brackets with a smile, matching the unlock animation glyph.
struct FaceIDGlyph: View {
    var color: Color = UnlockPalette.scanCyan
    var lineWidth: CGFloat? = nil

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let stroke = lineWidth ?? max(side * 0.085, 1.4)

            Canvas { context, size in
                let inset = side * 0.08
                let arm = side * 0.26
                let corner = side * 0.16
                let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)

                func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                    CGPoint(x: origin.x + x, y: origin.y + y)
                }

                var brackets = Path()

                // Top-left
                brackets.move(to: p(inset, inset + arm))
                brackets.addLine(to: p(inset, inset + corner))
                brackets.addQuadCurve(to: p(inset + corner, inset), control: p(inset, inset))
                brackets.addLine(to: p(inset + arm, inset))

                // Top-right
                brackets.move(to: p(side - inset - arm, inset))
                brackets.addLine(to: p(side - inset - corner, inset))
                brackets.addQuadCurve(to: p(side - inset, inset + corner), control: p(side - inset, inset))
                brackets.addLine(to: p(side - inset, inset + arm))

                // Bottom-right
                brackets.move(to: p(side - inset, side - inset - arm))
                brackets.addLine(to: p(side - inset, side - inset - corner))
                brackets.addQuadCurve(to: p(side - inset - corner, side - inset), control: p(side - inset, side - inset))
                brackets.addLine(to: p(side - inset - arm, side - inset))

                // Bottom-left
                brackets.move(to: p(inset + arm, side - inset))
                brackets.addLine(to: p(inset + corner, side - inset))
                brackets.addQuadCurve(to: p(inset, side - inset - corner), control: p(inset, side - inset))
                brackets.addLine(to: p(inset, side - inset - arm))

                context.stroke(
                    brackets,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round)
                )

                let eyeRadius = side * 0.05
                let eyeY = origin.y + side * 0.40
                let eyeSpread = side * 0.155
                let centerX = origin.x + side / 2

                let leftEye = CGRect(
                    x: centerX - eyeSpread - eyeRadius,
                    y: eyeY - eyeRadius,
                    width: eyeRadius * 2,
                    height: eyeRadius * 2
                )
                let rightEye = CGRect(
                    x: centerX + eyeSpread - eyeRadius,
                    y: eyeY - eyeRadius,
                    width: eyeRadius * 2,
                    height: eyeRadius * 2
                )
                context.fill(Path(ellipseIn: leftEye), with: .color(color))
                context.fill(Path(ellipseIn: rightEye), with: .color(color))

                var smile = Path()
                smile.addArc(
                    center: CGPoint(x: centerX, y: origin.y + side * 0.48),
                    radius: side * 0.20,
                    startAngle: .degrees(32),
                    endAngle: .degrees(148),
                    clockwise: false
                )
                context.stroke(
                    smile,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: stroke, lineCap: .round)
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

enum UnlockPalette {
    static let scanCyan = Color(red: 0.31, green: 0.86, blue: 0.98)
}

#Preview {
    FaceIDGlyph()
        .frame(width: 64, height: 64)
        .padding()
        .background(Color.black)
}
