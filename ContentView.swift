import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()

    @State private var throttle: Float = 0.0
    @State private var yaw: Float = 0.0
    @State private var pitch: Float = 0.0
    @State private var roll: Float = 0.0

    var body: some View {
        VStack(spacing: 20) {
            Text("ESPFlyController")
                .font(.largeTitle)
                .bold()

            Text(bleManager.statusText)
                .foregroundColor(bleManager.isConnected ? .green : .orange)

            VStack(spacing: 12) {
                Text("Throttle: \(throttle, specifier: "%.2f")")
                Slider(value: Binding(
                    get: { Double(throttle) },
                    set: {
                        throttle = Float($0)
                        sendControl()
                    }
                ), in: 0...1)

                Text("Yaw: \(yaw, specifier: "%.2f")")
                Slider(value: Binding(
                    get: { Double(yaw) },
                    set: {
                        yaw = Float($0)
                        sendControl()
                    }
                ), in: -1...1)

                Text("Pitch: \(pitch, specifier: "%.2f")")
                Slider(value: Binding(
                    get: { Double(pitch) },
                    set: {
                        pitch = Float($0)
                        sendControl()
                    }
                ), in: -1...1)

                Text("Roll: \(roll, specifier: "%.2f")")
                Slider(value: Binding(
                    get: { Double(roll) },
                    set: {
                        roll = Float($0)
                        sendControl()
                    }
                ), in: -1...1)
            }
            .padding()

            HStack(spacing: 16) {
                Button("Landen") {
                    bleManager.sendLand()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)

                Button("NOT-STOPP") {
                    bleManager.sendEmergencyStop()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private func sendControl() {
        bleManager.sendJoystick(
            throttle: throttle,
            yaw: yaw,
            pitch: pitch,
            roll: roll
        )
    }
}

#Preview {
    ContentView()
}