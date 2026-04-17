import SwiftUI

struct JoystickView: View {
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 160, height: 160)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                )

            Text("Joystick")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    JoystickView()
}