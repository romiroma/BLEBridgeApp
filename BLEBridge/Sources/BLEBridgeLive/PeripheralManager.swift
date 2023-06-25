
import Central
import Combine
import ComposableArchitecture
// MARK: - Peripheral Manager

extension DependencyValues.PeripheralManagerKey: DependencyKey {

    public static var liveValue: PeripheralManager = PeripheralManagerImpl(storage: DependencyValues.peripheralStorage,
                                                                           bluetoothQueue: DependencyValues.bluetoothQueue,
                                                                           cbCentralManager: DependencyValues.cbCentralManager,
                                                                           centralManagerDelegate: DependencyValues.centralManagerDelegate,
                                                                           serviceDiscoverer: DependencyValues.serviceDiscoverer,
                                                                           client: DependencyValues.client)
}

import CoreBluetooth

extension CBPeripheral: Identifiable {

    public var id: UUID { identifier }
}


class PeripheralManagerImpl: NSObject, PeripheralManager, CBPeripheralDelegate {

    private let peripheralStorage: Storage<CBPeripheral>
    private let serviceDiscoverer: ServiceDiscovererImpl
    private let bluetoothQueue: DispatchQueue
    private let cbCentralManager: CBCentralManager
    private let centralManagerDelegate: CentralManagerDelegate
    private let client: ClientImpl

    private var names: [UUID: PassthroughSubject<String?, Never>] = [:]
    private var rssi: [UUID: PassthroughSubject<Int, Never>] = [:]
    private var connectionStates: [UUID: PassthroughSubject<Bool, Never>] = [:]
    private var cancellables = Set<AnyCancellable>()

    init(storage: Storage<CBPeripheral>,
         bluetoothQueue: DispatchQueue,
         cbCentralManager: CBCentralManager,
         centralManagerDelegate: CentralManagerDelegate,
         serviceDiscoverer: ServiceDiscovererImpl,
         client: ClientImpl) {

        self.peripheralStorage = storage
        self.bluetoothQueue = bluetoothQueue
        self.cbCentralManager = cbCentralManager
        self.centralManagerDelegate = centralManagerDelegate
        self.serviceDiscoverer = serviceDiscoverer
        self.client = client

        super.init()

        centralManagerDelegate.connections.handleEvents(receiveOutput:  { [weak self] (peripheral: CBPeripheral, connected: Bool) in
            guard let self else { return }
            storage[peripheral.id] = peripheral
            self.connectionStatePublisher(id: peripheral.id)
            self.namePublisher(id: peripheral.id)
            peripheral.delegate = self
        }).sink { [unowned self] (peripheral: CBPeripheral, connected: Bool) in
            self.connectionStates[peripheral.id]?.send(connected)
        }.store(in: &cancellables)
    }

    func name(id: UUID) -> AnyPublisher<String?, Never> {

        return namePublisher(id: id).eraseToAnyPublisher()
    }

    func connect(id: UUID) {

        guard let peripheral = peripheralStorage[id] else { return }

        bluetoothQueue.async {
            self.cbCentralManager.connect(peripheral)
        }
    }

    func disconnect(id: UUID) {

        guard let peripheral = peripheralStorage[id] else { return }
        bluetoothQueue.async {
            self.cbCentralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func connectionState(id: UUID) -> AnyPublisher<Bool, Never> {

        return connectionStatePublisher(id: id).eraseToAnyPublisher()
    }

    func rssi(id: UUID, updateInterval: TimeInterval) -> AnyPublisher<Int, Never> {

        return Timer.publish(every: updateInterval, on: .main, in: .default)
            .autoconnect()
            .receive(on: bluetoothQueue)
            .handleEvents(receiveOutput: { [weak peripheral = peripheralStorage[id]] _ in
                guard let peripheral, peripheral.state == .connected else { return }
                peripheral.readRSSI()
            })
            .combineLatest(rssiPublisher(id: id))
            .map { $1 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    @discardableResult
    private func publisher<T>(keyPath: ReferenceWritableKeyPath<PeripheralManagerImpl, [UUID: PassthroughSubject<T, Never>]>, id: UUID) -> PassthroughSubject<T, Never> {
        let publisher: PassthroughSubject<T, Never>
        if let p = self[keyPath: keyPath][id] {
            publisher = p
        } else {
            publisher = .init()
            self[keyPath: keyPath][id] = publisher
        }
        return publisher
    }

    @discardableResult
    private func connectionStatePublisher(id: UUID) -> PassthroughSubject<Bool, Never> {
        publisher(keyPath: \.connectionStates, id: id)
    }

    @discardableResult
    private func namePublisher(id: UUID) -> PassthroughSubject<String?, Never> {
        publisher(keyPath: \.names, id: id)
    }

    @discardableResult
    private func rssiPublisher(id: UUID) -> PassthroughSubject<Int, Never> {
        publisher(keyPath: \.rssi, id: id)
    }

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {

        let id = peripheral.id
        let name = peripheral.name

        Task {
            self.namePublisher(id: id).send(name)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {

        rssiPublisher(id: peripheral.id).send(RSSI.intValue)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        serviceDiscoverer.peripheral(peripheral, didDiscoverServices: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {

        serviceDiscoverer.peripheral(peripheral, didDiscoverIncludedServicesFor: service, error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        serviceDiscoverer.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {

        client.peripheral(peripheral, didWriteValueFor: characteristic, error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        client.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
    }
}
