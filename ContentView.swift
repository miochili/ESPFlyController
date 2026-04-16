import SwiftUI
import Combine

class JoystickMonitor: ObservableObject {
    @Published var dx: Float = 0.0
    @Published var dy: Float = 0.0
}

struct ContentView: View {
    @StateObject private var monitor = JoystickMonitor()
    @StateObject private var udpClient = DroneUDPClient(host: "192.168.4.1", port: 5000)

    @State private var throttle: Float = 0.0
    @State private var timer: AnyCancellable?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Text("ESP FLY CONTROLLER")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                JoystickView(monitor: monitor)
                    .frame(width: 220, height: 220)

                HStack(spacing: 40) {
                    Button(action: {}) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.green)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in throttle = min(throttle + 0.05, 1.0) }
                            .onEnded   { _ in throttle = 0.0 }
                    )

                    Button(action: {}) {
                        Image(systemName: "arrow.down.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.red)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in throttle = max(throttle - 0.05, -1.0) }
                            .onEnded   { _ in throttle = 0.0 }
                    )
                }

                Button(action: {
                    udpClient.sendLanding()
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 80, height: 80)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                    }
                }
                .padding(.top, 10)

                Text("LAND")
                    .foregroundColor(.white)
                    .font(.caption)
            }
            .padding()
        }
        .onAppear {
            udpClient.start()
            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    udpClient.sendControl(
                        pitch:    monitor.dy,
                        roll:     monitor.dx,
                        yaw:      0.0,
                        throttle: throttle
                    )
                }
        }
        .onDisappear {
            timer?.cancel()
        }
    }
}
