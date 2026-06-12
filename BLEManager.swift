import Foundation
import CoreBluetooth

final class BLEManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var statusText = "Not connected"
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var isScanning = false
    @Published var showDeviceList = false

    // Aktuelle Steuerwerte – werden vom ContentView gesetzt
    var throttle: Float = 0.0
    var yaw: Float = 0.0
    var pitch: Float = 0.0
    var roll: Float = 0.0

    // Interner Zustand beim LAND-Fade
    private var isLanding = false

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?

    // Send-Timer: schickt alle 80ms JOY, solange verbunden
    private var sendTimer: Timer?

    // Muss exakt mit ESP-Code übereinstimmen
    private let targetDeviceName = "ESPFly-XIAO"
    private let serviceUUID      = CBUUID(string: "7A1F0001-6B8B-4E63-9FA5-1234567890AB")
    private let commandCharUUID  = CBUUID(string: "7A1F0003-6B8B-4E63-9FA5-1234567890AB")
    private let statusCharUUID   = CBUUID(string: "7A1F0002-6B8B-4E63-9FA5-1234567890AB")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Scan / Connect

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

    // MARK: - Send-Timer

    private func startSendTimer() {
        stopSendTimer()
        sendTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isLanding {
                // Pro Tick 0.04 runter -> ca. 2s von 1.0 auf 0.0
                self.throttle = max(0.0, self.throttle - 0.04)
                if self.throttle <= 0.0 {
                    self.throttle = 0.0
                    self.isLanding = false
                    self.sendRaw("LAND")
                    return
                }
            }
            self.sendJoyNow()
        }
    }

    private func stopSendTimer() {
        sendTimer?.invalidate()
        sendTimer = nil
    }

    // MARK: - Public Steuer-API

    /// Wird aus ContentView bei jeder Joystick-Änderung aufgerufen.
    /// Werte werden gespeichert und vom Timer kontinuierlich gesendet.
    func updateJoystick(throttle: Float, yaw: Float, pitch: Float, roll: Float) {
        self.throttle = throttle
        self.yaw = yaw
        self.pitch = pitch
        self.roll = roll
        isLanding = false
    }

    /// Startet sanften Throttle-Fade auf 0, dann sendet LAND.
    func sendLand() {
        isLanding = true
    }

    /// Sofortiger Notstopp – überschreibt alles.
    func sendEmergencyStop() {
        isLanding = false
        throttle = 0.0
        yaw = 0.0
        pitch = 0.0
        roll = 0.0
        sendRaw("STOP")
    }

    // MARK: - Internes Senden

    private func sendJoyNow() {
        let command = String(format: "JOY,%.3f,%.3f,%.3f,%.3f", throttle, yaw, pitch, roll)
        sendRaw(command)
    }

    private func sendRaw(_ string: String) {
        guard let peripheral = peripheral,
              let characteristic = commandCharacteristic,
              isConnected,
              let data = string.data(using: .utf8) else { return }
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }
}

// MARK: - CBCentralManagerDelegate

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
        stopSendTimer()
        statusText = "Disconnected"
    }
}

// MARK: - CBPeripheralDelegate

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
                startSendTimer()
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
