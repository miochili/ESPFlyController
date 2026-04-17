import SwiftUI
import Combine
import CoreBluetooth


class JoystickMonitor: ObservableObject {
    @Published var dx: Float = 0.0
    @Published var dy: Float = 0.0
}


final class BLEManager: NSObject, ObservableObject {
    @Published var connectionText: String = "Nicht verbunden"
    @Published var isConnected: Bool = false
    @Published var bluetoothReady: Bool = false

    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?

    private let serviceUUID = CBUUID(string: "7A1F0001-6B8B-4E63-9FA5-1234567890AB")
    private let statusCharUUID = CBUUID(string: "7A1F0002-6B8B-4E63-9FA5-1234567890AB")
    private let targetName = "ESPFly-XIAO"
    
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


struct ContentView: View {
    @StateObject private var monitor = JoystickMonitor()
    @StateObject private var bleManager = BLEManager()
    @StateObject private var udpClient = DroneUDPClient(host: "192.168.4.1", port: 5000)

    @State private var throttle: Float = 0.0
    @State private var timer: AnyCancellable?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                // BLE STATUS OBEN
                HStack {
                    Circle()
                        .fill(bleManager.isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)

                    Text(bleManager.connectionText)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button("Neu verbinden") {
                        bleManager.startScan()
                    }
                    .foregroundColor(.white)
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Divider()
                    .background(Color.white)

                Text("ESP FLY CONTROLLER")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                JoystickView(monitor: monitor)
                    .frame(width: 220, height: 220)

                HStack(spacing: 40) {
                    Button(action: {}) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.green)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in throttle = min(throttle + 0.05, 1.0) }
                            .onEnded   { _ in throttle = 0.0 }
                    )

                    Button(action: {}) {
                        Image(systemName: "arrow.down.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.red)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in throttle = max(throttle - 0.05, -1.0) }
                            .onEnded   { _ in throttle = 0.0 }
                    )
                }

                Button(action: {
                    bleManager.isConnected ? udpClient.sendLanding() : {}
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 80, height: 80)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                    }
                }
                .padding(.top, 10)

                Text("LAND")
                    .foregroundColor(.white)
                    .font(.caption)
            }
            .padding()
        }
        .onAppear {
            bleManager.start()
            udpClient.start()
            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    if bleManager.isConnected {
                        // Später: BLE senden statt UDP
                        udpClient.sendControl(
                            pitch:    monitor.dy,
                            roll:     monitor.dx,
                            yaw:      0.0,
                            throttle: throttle
                        )
                    }
                }
        }
        .onDisappear {
            timer?.cancel()
        }
    }
}

#Preview {
    ContentView()
}