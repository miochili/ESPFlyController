import SwiftUI

struct JoystickView: View {
    @Binding var throttle: Float
    @Binding var yaw: Float
    @Binding var pitch: Float
    @Binding var roll: Float
    var onChange: () -> Void

    @State private var knobPosition: CGSize = .zero

    private let outerSize: CGFloat = 220
    private let innerSize: CGFloat = 90

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: outerSize, height: outerSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                )

            Circle()
                .fill(Color.white.opacity(0.03))
                .frame(width: outerSize * 0.72, height: outerSize * 0.72)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.65)],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 60
                    )
                )
                .frame(width: innerSize, height: innerSize)
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
                .offset(knobPosition)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let radius = (outerSize - innerSize) / 2
                            let x = max(-radius, min(radius, value.translation.width))
                            let y = max(-radius, min(radius, value.translation.height))
                            knobPosition = CGSize(width: x, height: y)

                            yaw = Float(x / radius)
                            pitch = Float(-y / radius)
                            roll = yaw
                            onChange()
                        }
                        .onEnded { _ in
                            knobPosition = .zero
                            yaw = 0
                            pitch = 0
                            roll = 0
                            onChange()
                        }
                )
        }
    }
}

#Preview {
    JoystickView(
        throttle: .constant(0),
        yaw: .constant(0),
        pitch: .constant(0),
        roll: .constant(0),
        onChange: {}
    )
}
