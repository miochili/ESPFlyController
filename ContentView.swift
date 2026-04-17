import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()

    @State private var throttle: Float = 0.0
    @State private var yaw: Float = 0.0
    @State private var pitch: Float = 0.0
    @State private var roll: Float = 0.0

    var body: some View {
        ZStack {
            Image("drone_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.62).ignoresSafeArea())

            VStack(spacing: 18) {
                header
                overviewCard

                Spacer(minLength: 18)

                JoystickView(
                    throttle: $throttle,
                    yaw: $yaw,
                    pitch: $pitch,
                    roll: $roll,
                    onChange: sendControl
                )
                .frame(width: 280, height: 280)

                controlRow
                landButton

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 14)
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("ESP Fly Controller")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("BLE")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private var overviewCard: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(red: 0.10, green: 0.10, blue: 0.10))
            .frame(height: 118)
            .overlay(
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(bleManager.isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)

                        Text(bleManager.isConnected ? "Connected" : "Disconnected")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))

                        Spacer()
                    }

                    HStack(spacing: 10) {
                        statBox(title: "Pitch", value: pitch)
                        statBox(title: "Roll", value: roll)
                        statBox(title: "Yaw", value: yaw)
                        statBox(title: "Throttle", value: throttle)
                    }
                }
                .padding(18)
            )
    }

    private var controlRow: some View {
        HStack(spacing: 18) {
            Button(action: {
                throttle = min(1.0, throttle + 0.1)
                sendControl()
            }) {
                CircleButton(symbol: "arrow.up", color: .green, size: 86)
            }

            Button(action: {
                bleManager.sendEmergencyStop()
            }) {
                CircleButton(symbol: "stop.fill", color: Color(white: 0.18), size: 86)
            }

            Button(action: {
                throttle = max(0.0, throttle - 0.1)
                sendControl()
            }) {
                CircleButton(symbol: "arrow.down", color: .red, size: 86)
            }
        }
        .padding(.top, 4)
    }

    private var landButton: some View {
        Button(action: {
            bleManager.sendLand()
        }) {
            Text("LANDEN")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white.opacity(0.10))
                .foregroundColor(.white)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .padding(.top, 2)
    }

    private func sendControl() {
        bleManager.sendJoystick(throttle: throttle, yaw: yaw, pitch: pitch, roll: roll)
    }

    private func statBox(title: String, value: Float) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
            Text(String(format: "%+.2f", value))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }
}

struct CircleButton: View {
    let symbol: String
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
            Image(systemName: symbol)
                .font(.system(size: size * 0.30, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: color.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
}
