
import BLEBridge
import Central
import Combine
import ComposableArchitecture
import CoreBluetooth

extension DependencyValues {

    static let peripheralStorage = Storage<CBPeripheral>()
    static let servicesStorage = Storage<CBService>()
    static let bluetoothQueue = DispatchQueue(label: "com.BLEBridgeLive.queue", qos: .utility)
    static let cbCentralManager = CBCentralManager(delegate: centralManagerDelegate,
                                                   queue: bluetoothQueue,
                                                   options: [
                                                    CBCentralManagerOptionShowPowerAlertKey: 1
                                                   ])
    static let centralManagerDelegate = CentralManagerDelegate()
    static let authorization = AuthorizationProviderImpl()
    static let serviceDiscoverer = ServiceDiscovererImpl(peripheralStorage: DependencyValues.peripheralStorage,
                                                         bluetoothQueue: DependencyValues.bluetoothQueue,
                                                         servicesStorage: DependencyValues.servicesStorage)
    static let client = ClientImpl(
        bluetoothQueue: DependencyValues.bluetoothQueue,
        peripheralStorage: DependencyValues.peripheralStorage,
        servicesStorage: DependencyValues.servicesStorage
    )
}

extension Store where State == BLEBridge.State, Action == BLEBridge.Action {

    public static func live() -> StoreOf<BLEBridge> {
        .init(initialState: .init(), reducer: BLEBridge.init)
    }
}

// MARK: - Central Scanner

extension DependencyValues.CentralScannerKey: DependencyKey {

    public static var liveValue: CentralScanner = CentralScannerImpl(cbCentralManager: DependencyValues.cbCentralManager, bluetoothQueue: DependencyValues.bluetoothQueue)
}

class CentralScannerImpl: CentralScanner {

    private let cbCentralManager: CBCentralManager
    private let queue: DispatchQueue
    private var cancellables = Set<AnyCancellable>()

    init(cbCentralManager: CBCentralManager,
         bluetoothQueue: DispatchQueue) {

        self.cbCentralManager = cbCentralManager
        self.queue = bluetoothQueue
    }

    var state: AnyPublisher<Bool, Never> {

        cbCentralManager.publisher(for: \.isScanning)
            .eraseToAnyPublisher()
    }

    func start() {

        queue.async {
            self.cbCentralManager.scanForPeripherals(withServices: nil)
        }
    }

    func stop() {

        queue.async {
            self.cbCentralManager.stopScan()
        }
    }
}

// MARK: - Central State Provider

extension DependencyValues.CentralStateProviderKey: DependencyKey {

    public static var liveValue: CentralStateProvider = CentralStateProviderImpl(cbCentralManager: DependencyValues.cbCentralManager,
                                                                                 centralManagerDelegate: DependencyValues.centralManagerDelegate)
}

class CentralStateProviderImpl: CentralStateProvider {

    private let cbCentralManager: CBCentralManager
    private let centralManagerDelegate: CentralManagerDelegate

    init(cbCentralManager: CBCentralManager,
         centralManagerDelegate: CentralManagerDelegate) {

        self.cbCentralManager = cbCentralManager
        self.centralManagerDelegate = centralManagerDelegate
    }

    var state: AnyPublisher<Central.State.Update, Never> {

        centralManagerDelegate.centralState.eraseToAnyPublisher()
    }
}

extension Central.State.Update {

    init(_ state: CBManagerState) {

        switch state {
        case .unsupported:
            self = .unsupported
        case .resetting:
            self = .resetting
        case .poweredOff:
            self = .poweredOff
        case .poweredOn:
            self = .poweredOn
        case .unauthorized, .unknown:
            self = .unauthorized
        @unknown default:
            assertionFailure("Unknown state \(state)")
            self = .unauthorized
        }
    }
}


// MARK: - Authorization

extension DependencyValues.AuthorizationProviderKey: DependencyKey {

    public static var liveValue: any AuthorizationProvider {

        DependencyValues.authorization
    }
}

class AuthorizationProviderImpl: AuthorizationProvider {

    private(set) lazy var authorization: AnyPublisher<CBManagerAuthorization, Never> = Just(CBCentralManager.authorization)
        .eraseToAnyPublisher()
}

// MARK: - Peripherals Discoverer

extension DependencyValues.PeripheralsDiscovererKey: DependencyKey {

    public static var liveValue: PeripheralsDiscoverer = PeripheralsDiscovererImpl(storage: DependencyValues.peripheralStorage,
                                                                                   centralManagerDelegate: DependencyValues.centralManagerDelegate)
}

class PeripheralsDiscovererImpl: PeripheralsDiscoverer {

    private let storage: Storage<CBPeripheral>
    private let centralManagerDelegate: CentralManagerDelegate

    init(storage: Storage<CBPeripheral>,
         centralManagerDelegate: CentralManagerDelegate) {

        self.storage = storage
        self.centralManagerDelegate = centralManagerDelegate
    }

    var peripherals: AnyPublisher<(id: UUID, name: String?, rssi: Int), Never> {

        centralManagerDelegate.peripherals.handleEvents(receiveOutput:  { [weak self] in

            guard let self else { return }
            let id = $0.peripheral.id
            guard storage[id] == nil else { return }
            storage[id] = $0.peripheral
        }).map {
            return ($0.peripheral.identifier, $0.peripheral.name, $0.rssi.intValue)
        }.eraseToAnyPublisher()
    }
}
