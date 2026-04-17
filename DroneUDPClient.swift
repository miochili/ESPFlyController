import Foundation

final class DroneUDPClient: ObservableObject {
    func sendJoystick(throttle: Float, yaw: Float, pitch: Float, roll: Float) {}
    func sendLanding() {}
    func sendEmergencyStop() {}
}