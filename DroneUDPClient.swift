import Foundation

final class DroneUDPClient: ObservableObject {
    func sendJoystick(throttle: Float, yaw: Float, pitch: Float, roll: Float) {
        let command = String(format: "JOY,%.3f,%.3f,%.3f,%.3f", throttle, yaw, pitch, roll)
        print("UDP send: \(command)")
    }

    func sendLanding() {
        print("UDP send: LAND")
    }

    func sendEmergencyStop() {
        print("UDP send: STOP")
    }
}
