import Foundation
import CoreBluetooth

final class BLEManager: NSObject, ObservableObject {
    @Published var connectionText: String = "Nicht verbunden"
    @Published var isConnected: Bool = false
    @Published var bluetoothReady: Bool = false

    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?

    private let serviceUUID = CBUUID(string: "7A1F0001-6B8B-4E63-9FA5-1234567890AB")
    private let statusCharUUID = CBUUID(string: "7A1F0002-6B8B-4E63-9FA5-1234567890AB")
    private let targetName = "ESPFly-XIAO"
}

extension BLEManager {
    func start() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: .main)
        } else if centralManager.state == .poweredOn {
            startScan()
        }
    }

    func startScan() {
        guard centralManager.state == .poweredOn else {
            bluetoothReady = false
            isConnected = false
            connectionText = "Bluetooth aus"
            return
        }

        bluetoothReady = true
        isConnected = false
        connectionText = "Suche ESPFly-XIAO ..."
        centralManager.stopScan()
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }

    func disconnect() {
        guard let peripheral = targetPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bluetoothReady = true
            connectionText = "Suche ESPFly-XIAO ..."
            startScan()
        case .poweredOff:
            bluetoothReady = false
            isConnected = false
            connectionText = "Bluetooth aus"
        case .unauthorized:
            bluetoothReady = false
            isConnected = false
            connectionText = "Bluetooth nicht erlaubt"
        case .unsupported:
            bluetoothReady = false
            isConnected = false
            connectionText = "BLE nicht unterstützt"
        default:
            bluetoothReady = false
            isConnected = false
            connectionText = "Bluetooth nicht bereit"
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""

        if name == targetName {
            targetPeripheral = peripheral
            targetPeripheral?.delegate = self
            centralManager.stopScan()
            connectionText = "Verbinde ..."
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectionText = "Verbunden"
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        connectionText = "Nicht verbunden"
        targetPeripheral = nil
        startScan()
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        connectionText = "Nicht verbunden"
        targetPeripheral = nil
        startScan()
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([statusCharUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
    }
}