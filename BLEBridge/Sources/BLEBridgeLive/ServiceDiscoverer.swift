
import Central
import Combine
import ComposableArchitecture
import CoreBluetooth

extension DependencyValues.ServiceDiscovererKey: DependencyKey {

    public static var liveValue: ServiceDiscoverer = DependencyValues.serviceDiscoverer
}

class ServiceDiscovererImpl: NSObject, ServiceDiscoverer {

    private let peripheralStorage: Storage<CBPeripheral>
    private let servicesStorage: Storage<CBService>
    private let bluetoothQueue: DispatchQueue
    private var services: [String: PassthroughSubject<[Service.Discovered], Never>] = [:]
    private var characteristics: [String: PassthroughSubject<[Characteristic.Discovered], Never>] = [:]

    init(peripheralStorage: Storage<CBPeripheral>,
         bluetoothQueue: DispatchQueue,
         servicesStorage: Storage<CBService>) {

        self.bluetoothQueue = bluetoothQueue
        self.servicesStorage = servicesStorage
        self.peripheralStorage = peripheralStorage
        super.init()
    }

    func services(ofPeripheralWithID peripheralID: UUID) -> AnyPublisher<[Service.Discovered], Never> {

        guard let peripheral = peripheralStorage[peripheralID] else {
            return Just([]).eraseToAnyPublisher()
        }
        bluetoothQueue.async {
             peripheral.discoverServices([])
        }
        return servicesPublisher(peripheralID.uuidString).eraseToAnyPublisher()
    }

    func includedServices(ofServiceWithID serviceID: CBUUID) -> AnyPublisher<[Service.Discovered], Never> {

        guard let service = servicesStorage[serviceID],
              let peripheral = service.peripheral else {
            return Just([]).eraseToAnyPublisher()
        }
        bluetoothQueue.async {
            peripheral.discoverIncludedServices([], for: service)
        }
        return servicesPublisher(serviceID.uuidString).eraseToAnyPublisher()
    }

    func characteristics(ofServiceWithID serviceID: CBUUID) -> AnyPublisher<[Characteristic.Discovered], Never> {

        guard let service = servicesStorage[serviceID],
              let peripheral = service.peripheral else {
            return Just([]).eraseToAnyPublisher()
        }
        bluetoothQueue.async {
            peripheral.discoverCharacteristics([], for: service)
        }
        return characteristicsPublisher(serviceID.uuidString).eraseToAnyPublisher()
    }

    @discardableResult
    private func publisher<T>(
        keyPath: ReferenceWritableKeyPath<ServiceDiscovererImpl, [String: PassthroughSubject<T, Never>]>,
        id: String
    ) -> PassthroughSubject<T, Never> {

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
    private func servicesPublisher(_ id: String) -> PassthroughSubject<[Service.Discovered], Never> {
        publisher(keyPath: \.services, id: id)
    }

    @discardableResult
    private func characteristicsPublisher(_ id: String) -> PassthroughSubject<[Characteristic.Discovered], Never> {
        publisher(keyPath: \.characteristics, id: id)
    }
}

extension ServiceDiscovererImpl: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        let id = peripheral.id
        let services = peripheral.services ?? []

        Task {
            var discovered = [Service.Discovered]()

            for service in services {
                self.servicesStorage[service.id] = service
                discovered.append(Service.Discovered.init(id: service.id, name: service.uuid.uuidString))
            }
            self.servicesPublisher(id.uuidString).send(discovered)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        let id = service.id
        let characteristics = service.characteristics ?? []

        Task {
            var discovered = [Characteristic.Discovered]()
            for characteristic in characteristics {
                discovered.append(Characteristic.Discovered.init(id: characteristic.id,
                                                                 name: characteristic.uuid.uuidString,
                                                                 property: characteristic.properties))
            }
            self.characteristicsPublisher(id.uuidString).send(discovered)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {

        let id = service.id
        let services = service.includedServices ?? []

        Task {
            var discovered = [Service.Discovered]()
            for service in services {
                self.servicesStorage[service.id] = service
                discovered.append(Service.Discovered.init(id: service.id,
                                                          name: service.uuid.uuidString))
            }
            self.servicesPublisher(id.uuidString).send(discovered)
        }
    }
}

extension CBService: Identifiable {

    public var id: CBUUID { uuid }
}

extension CBCharacteristic: Identifiable {

    public var id: CBUUID { uuid }
}

extension Characteristic.Property.Usage {

    var cbCharacteristicProperty: CBCharacteristicProperties {

        switch self {
        case .broadcast:
            return .broadcast
        case .read:
            return .read
        case .writeWithoutResponse:
            return .writeWithoutResponse
        case .write:
            return .write
        case .notify:
            return .notify
        case .indicate:
            return .indicate
        case .authenticatedSignedWrites:
            return .authenticatedSignedWrites
        case .extendedProperties:
            return .extendedProperties
        }
    }
}
