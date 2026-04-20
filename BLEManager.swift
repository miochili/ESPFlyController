import Foundation
import CoreBluetooth

final class BLEManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var statusText = "Not connected"
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var isScanning = false
    @Published var showDeviceList = false

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?

    // Muss exakt mit ESP-Code übereinstimmen
    private let targetDeviceName = "ESPFly-XIAO"
    private let serviceUUID      = CBUUID(string: "7A1F0001-6B8B-4E63-9FA5-1234567890AB")
    private let commandCharUUID  = CBUUID(string: "7A1F0003-6B8B-4E63-9FA5-1234567890AB")
    private let statusCharUUID   = CBUUID(string: "7A1F0002-6B8B-4E63-9FA5-1234567890AB")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        discoveredDevices = []
        isScanning = true
        showDeviceList = true
        statusText = "Scanning for devices ..."
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            if self.isScanning { self.stopScan() }
        }
    }

    func stopScan() {
        centralManager.stopScan()
        isScanning = false
        if !isConnected { statusText = "Scan finished" }
    }

    func connect(to device: CBPeripheral) {
        peripheral = device
        peripheral?.delegate = self
        centralManager.stopScan()
        isScanning = false
        showDeviceList = false
        statusText = "Connecting to \(device.name ?? "Device") ..."
        centralManager.connect(device, options: nil)
    }

    func disconnect() {
        guard let peripheral = peripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    func sendJoystick(throttle: Float, yaw: Float, pitch: Float, roll: Float) {
        let command = String(format: "JOY,%.3f,%.3f,%.3f,%.3f", throttle, yaw, pitch, roll)
        send(command)
    }

    func sendLand() { send("LAND") }
    func sendEmergencyStop() { send("STOP") }

    private func send(_ string: String) {
        guard let peripheral = peripheral,
              let characteristic = commandCharacteristic,
              let data = string.data(using: .utf8) else { return }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:    statusText = "Not connected"
        case .poweredOff:   statusText = "Bluetooth is off"
        case .unauthorized: statusText = "Bluetooth not allowed"
        case .unsupported:  statusText = "Bluetooth not supported"
        default:            statusText = "Bluetooth not ready"
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        guard let name = peripheral.name, !name.isEmpty else { return }
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        isConnected = true
        statusText = "Connected to \(peripheral.name ?? targetDeviceName)"
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        statusText = "Connection failed"
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        commandCharacteristic = nil
        statusText = "Disconnected"
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([commandCharUUID, statusCharUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == commandCharUUID {
                commandCharacteristic = characteristic
                statusText = "BLE ready"
            }
            if characteristic.uuid == statusCharUUID {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard characteristic.uuid == statusCharUUID,
              let data = characteristic.value,
              let text = String(data: data, encoding: .utf8) else { return }
        DispatchQueue.main.async {
            self.statusText = "ESP: \(text)"
        }
    }
}
