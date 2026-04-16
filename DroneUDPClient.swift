import Foundation
import Network

final class DroneUDPClient: ObservableObject {
    private var connection: NWConnection?
    private let host: NWEndpoint.Host
    private let port: NWEndpoint.Port

    init(host: String, port: UInt16) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
    }

    func start() {
        connection = NWConnection(
            host: host,
            port: port,
            using: .udp
        )
        connection?.start(queue: .global())
    }

    func sendControl(pitch: Float, roll: Float, yaw: Float, throttle: Float) {
        var data = Data()
        data.append(floatToBytes(pitch))
        data.append(floatToBytes(roll))
        data.append(floatToBytes(yaw))
        data.append(floatToBytes(throttle))
        data.append(UInt8(0))
        connection?.send(content: data, completion: .idempotent)
    }

    func sendLanding() {
        var data = Data()
        data.append(floatToBytes(0))
        data.append(floatToBytes(0))
        data.append(floatToBytes(0))
        data.append(floatToBytes(0))
        data.append(UInt8(1))
        connection?.send(content: data, completion: .idempotent)
    }

    private func floatToBytes(_ value: Float) -> Data {
        var v = value
        return Data(bytes: &v, count: 4)
    }
}
