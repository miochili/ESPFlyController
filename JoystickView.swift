import SwiftUI

struct JoystickView: View {
    @Binding var throttle: Float
    @Binding var yaw: Float
    @Binding var pitch: Float
    @Binding var roll: Float
    var onChange: () -> Void

    @State private var knobPosition: CGSize = .zero

    private let outerSize: CGFloat = 240
    private let innerSize: CGFloat = 110

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.18))
                    .frame(width: outerSize, height: outerSize)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.45), lineWidth: 3)
                    )

                Circle()
                    .fill(Color.white)
                    .frame(width: innerSize, height: innerSize)
                    .overlay(
                        Circle()
                            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 2)
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

            Text("Joystick")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    JoystickView(
        throttle: .constant(0.5),
        yaw: .constant(0),
        pitch: .constant(0),
        roll: .constant(0),
        onChange: {}
    )
}
