import Foundation
import CoreBluetooth

final class BLEManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var statusText = "Suche ESPFly-XIA ..."

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?

    private let targetDeviceName = "ESPFly-XIA"

    // Diese UUIDs müssen später exakt zu deinem ESP32-BLE-Code passen
    private let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890AB")
    private let characteristicUUID = CBUUID(string: "87654321-4321-4321-4321-BA0987654321")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func sendJoystick(throttle: Float, yaw: Float, pitch: Float, roll: Float) {
        let command = String(format: "JOY,%.3f,%.3f,%.3f,%.3f", throttle, yaw, pitch, roll)
        send(command)
    }

    func sendLand() {
        send("LAND")
    }

    func sendEmergencyStop() {
        send("STOP")
    }

    private func send(_ string: String) {
        guard let peripheral = peripheral,
              let characteristic = commandCharacteristic,
              let data = string.data(using: .utf8) else {
            return
        }

        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusText = "Suche ESPFly-XIA ..."
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        case .poweredOff:
            statusText = "Bluetooth ist aus"
        case .unauthorized:
            statusText = "Bluetooth nicht erlaubt"
        case .unsupported:
            statusText = "Bluetooth nicht unterstützt"
        default:
            statusText = "Bluetooth nicht bereit"
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if peripheral.name == targetDeviceName {
            statusText = "Verbinde mit \(targetDeviceName) ..."
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            centralManager.stopScan()
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        statusText = "Verbunden mit \(targetDeviceName)"
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        statusText = "Verbindung fehlgeschlagen"
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        commandCharacteristic = nil
        statusText = "Getrennt – suche erneut ..."
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics where characteristic.uuid == characteristicUUID {
            commandCharacteristic = characteristic
            statusText = "BLE bereit"
        }
    }
}
