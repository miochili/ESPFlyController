import SwiftUI

struct JoystickView: View {
    @ObservedObject var monitor: JoystickMonitor

    let baseRadius: CGFloat = 110
    let knobRadius: CGFloat = 40

    @State private var knobPosition: CGSize = .zero

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: baseRadius * 2, height: baseRadius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                )

            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: knobRadius * 2, height: knobRadius * 2)
                .offset(knobPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let x = value.translation.width
                            let y = value.translation.height
                            let dist = sqrt(x*x + y*y)
                            let maxDist = baseRadius - knobRadius
                            if dist <= maxDist {
                                knobPosition = CGSize(width: x, height: y)
                            } else {
                                let angle = atan2(y, x)
                                knobPosition = CGSize(
                                    width: cos(angle) * maxDist,
                                    height: sin(angle) * maxDist
                                )
                            }
                            let maxD = Float(baseRadius - knobRadius)
                            monitor.dx =  Float(knobPosition.width)  / maxD
                            monitor.dy = -Float(knobPosition.height) / maxD
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                knobPosition = .zero
                            }
                            monitor.dx = 0
                            monitor.dy = 0
                        }
                )
        }
    }
}
