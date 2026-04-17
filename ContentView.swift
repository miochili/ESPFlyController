import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()

    @State private var throttle: Float = 0.5
    @State private var yaw: Float = 0.0
    @State private var pitch: Float = 0.0
    @State private var roll: Float = 0.0

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("ESPFlyController")
                    .font(.title2)
                    .bold()

                Spacer()

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(bleManager.isConnected ? Color.green.opacity(0.25) : Color.red.opacity(0.25))
                    .frame(width: 88, height: 34)
                    .overlay(
                        Text(bleManager.isConnected ? "Verbunden" : "Offline")
                            .font(.caption)
                            .foregroundColor(bleManager.isConnected ? .green : .red)
                    )
            }
            .padding(.horizontal)

            VStack(spacing: 10) {
                JoystickView(
                    throttle: $throttle,
                    yaw: $yaw,
                    pitch: $pitch,
                    roll: $roll,
                    onChange: sendControl
                )
                .frame(height: 340)

                HStack(spacing: 14) {
                    Button(action: {
                        throttle = min(1.0, throttle + 0.1)
                        sendControl()
                    }) {
                        Text("UP")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }

                    Button(action: {
                        throttle = max(0.0, throttle - 0.1)
                        sendControl()
                    }) {
                        Text("DOWN")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    bleManager.sendLand()
                }) {
                    Text("LANDEN")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.top, 4)

                Button(action: {
                    bleManager.sendEmergencyStop()
                }) {
                    Text("NOT-STOPP")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top, 10)
    }

    private func sendControl() {
        bleManager.sendJoystick(throttle: throttle, yaw: yaw, pitch: pitch, roll: roll)
    }
}

#Preview {
    ContentView()
}
