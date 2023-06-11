
import Combine
import ComposableArchitecture
import CoreBluetooth
import Foundation

public struct Peripheral: ReducerProtocol {

    @Dependency(\.peripheralManager) var peripheralManager
    @Dependency(\.servicesDiscoverer) var servicesDiscoverer
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.client) var client

    public init() {}

    public struct State: Identifiable, Hashable, Equatable {

        public var id: UUID
        public var name: String?
        public var RSSI: Int
        public var connection: Connection.State = .disconnected
        public var serviceDiscover: Service.Discover.State = .idle([])
        public var services: IdentifiedArrayOf<Service.State> = []

        public var selected: Service.State.ID?
        public var selectedService: Service.State? {

            guard let selected else { return nil }
            return services[id: selected]
        }

        init(id: UUID, name: String? = nil, RSSI: Int) {
            self.id = id
            self.name = name
            self.RSSI = RSSI
        }
    }

    public enum Action: Equatable {

        case activate
        case updateRSSI(rssi: Int)
        case connection(Connection.Action)
        case serviceDiscover(Service.Discover.Action)
        case services(id: Service.State.ID, action: Service.Action)
        case selectedService(Service.Action)
        case selectService(Service.State.ID?)

        case stopDataExchange
        case didRead(Data)
        case write(Data)
        case didWrite
    }

    enum CancelID: Hashable {
        case activation(id: UUID)
        case connection(id: UUID)
        case dataInput(id: UUID)
        case dataOutput(id: UUID)
    }

    public var body: some ReducerProtocolOf<Peripheral> {

        Scope(state: \.connection, action: /Peripheral.Action.connection, child: Connection.init)
        Scope(state: \.serviceDiscover, action: /Peripheral.Action.serviceDiscover, child: Service.Discover.init)

        .forEach(\.services, action: /Action.services, element: Service.init)

        Reduce { state, action in

            switch action {
            case let .updateRSSI(rssi: rssi):
                state.RSSI = rssi
            case .connection(.connect) where state.connection == .connecting:
                let id = state.id
                return EffectTask.concatenate(
                    EffectTask.run(operation: {
                        await $0(.activate)
                    }),
                    EffectTask.run { _ in
                        peripheralManager.connect(id: id)
                    }
                )

            case .connection(.connect):
                return .send(.activate)
            case .connection(.disconnect) where state.connection == .disconnecting:
                peripheralManager.disconnect(id: state.id)
            case .connection(.disconnect):
                break
            case .connection(.updateConection(isConnected: true)):
                let id = state.id
                state.selected = nil
                return EffectTask.merge (
                    .send(.serviceDiscover(.discover)),
                    EffectTask.publisher {
                        servicesDiscoverer.services(ofPeripheralWithID: id)
                            .map { Action.serviceDiscover(.discovered($0)) }
                            .receive(on: mainQueue)
                    },
                    EffectTask.publisher {
                        peripheralManager.rssi(id: id, updateInterval: 1)
                            .map { Action.updateRSSI(rssi: $0) }
                            .receive(on: mainQueue)
                    }
                )
                .cancellable(id: CancelID.connection(id: id), cancelInFlight: true)
            case .connection(.updateConection(isConnected: false)):
                return EffectTask.cancel(id: CancelID.connection(id: state.id))
            case .serviceDiscover(.discovered(let IDs)):
                var services = [Service.State]()
                for discovered in IDs {
                    services.append(Service.State.init(id: discovered.id, name: discovered.name))
                }
                state.services = .init(uniqueElements: services)
            case .activate:
                let id = state.id
                let tasks = [
                    EffectTask.publisher {
                        peripheralManager.connectionState(id: id)
                            .map { Action.connection(.updateConection(isConnected: $0)) }
                            .receive(on: mainQueue)
                    }
                ]
                return EffectTask
                    .merge(tasks)
                    .cancellable(id: CancelID.activation(id: id), cancelInFlight: true)
            case .serviceDiscover(.discover):
                break
            case .selectService(let id):
                state.selected = id
                return EffectTask.run {
                    await $0(.selectedService(.activate))
                }
            case .selectedService(let action):
                guard let id = state.selected else {
                    break
                }
                return .send(.services(id: id, action: action))
            case .services(id: let serviceID, action: .publish):
                let peripheralID = state.id
                guard let service = state.services[id: serviceID],
                      let rx = service.rx,
                      let tx = service.tx else {
                    break
                }
                return EffectTask.merge(
                    EffectTask.publisher{
                        client.start(
                            peripheralID: peripheralID,
                            serviceID: service.id,
                            rxID: rx,
                            txID: tx
                        )
                        .map { _ in Action.didWrite }
                        .receive(on: mainQueue)
                    }
                        .cancellable(id: CancelID.dataInput(id: peripheralID)),
                    EffectTask.publisher {
                        client.output
                            .map(Action.didRead)
                            .receive(on: mainQueue)
                    }
                        .cancellable(id: CancelID.dataInput(id: peripheralID))
                )
            case .write(let data):
                client.input.send(data)
            case .stopDataExchange:
                client.stop()
                let id = state.id
                return EffectTask.merge(
                    EffectTask.cancel(id: CancelID.dataInput(id: id)),
                    EffectTask.cancel(id: CancelID.dataOutput(id: id))
                )
            default:
                break
            }
            return .none
        }
    }
}

public protocol PeripheralManager {

    func connect(id: UUID)
    func disconnect(id: UUID)
    func connectionState(id: UUID) -> AnyPublisher<Bool, Never>
    func name(id: UUID) -> AnyPublisher<String?, Never>
    func rssi(id: UUID, updateInterval: TimeInterval) -> AnyPublisher<Int, Never>
}

public protocol ServiceDiscoverer {

    func services(ofPeripheralWithID peripheralID: UUID) -> AnyPublisher<[Service.Discovered], Never>
    func includedServices(ofServiceWithID serviceID: CBUUID) -> AnyPublisher<[Service.Discovered], Never>
    func characteristics(ofServiceWithID serviceID: CBUUID) -> AnyPublisher<[Characteristic.Discovered], Never>
}

extension DependencyValues {

    public struct PeripheralManagerKey: TestDependencyKey {

        public static let testValue: PeripheralManager = PeripheralManagerMock()
    }

    public var peripheralManager: PeripheralManager {

        get {
            self[PeripheralManagerKey.self]
        }
        set {
            self[PeripheralManagerKey.self] = newValue
        }
    }

    public struct ServiceDiscovererKey: TestDependencyKey {

        public static let testValue: ServiceDiscoverer = ServiceDiscovererMock()
    }

    public var servicesDiscoverer: ServiceDiscoverer {

        get {
            self[ServiceDiscovererKey.self]
        }
        set {
            self[ServiceDiscovererKey.self] = newValue
        }
    }
}

struct PeripheralManagerMock: PeripheralManager {

    func connect(id: UUID) {

    }

    func disconnect(id: UUID) {

    }

    func connectionState(id: UUID) -> AnyPublisher<Bool, Never> {

        Just(true).eraseToAnyPublisher()
    }

    func rssi(id: UUID, updateInterval: TimeInterval) -> AnyPublisher<Int, Never> {

        Timer.TimerPublisher(interval: updateInterval,
                             runLoop: .main,
                             mode: .common).map { _ in
            -45
        }.eraseToAnyPublisher()
    }

    func name(id: UUID) -> AnyPublisher<String?, Never> {

        Just("Test Device").eraseToAnyPublisher()
    }
}

struct ServiceDiscovererMock: ServiceDiscoverer {

    func services(ofPeripheralWithID peripheralID: UUID) -> AnyPublisher<[Service.Discovered], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func includedServices(ofServiceWithID serviceID: CBUUID) -> AnyPublisher<[Service.Discovered], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func characteristics(ofServiceWithID serviceID: CBUUID) -> AnyPublisher<[Characteristic.Discovered], Never> {
        Just([]).eraseToAnyPublisher()
    }
}

public protocol Client {

    func start(
        peripheralID: UUID,
        serviceID: CBUUID,
        rxID: CBUUID,
        txID: CBUUID
    ) -> AnyPublisher<Void, Never>

    func stop()

    var input: PassthroughSubject<Data, Never> { get }
    var output: AnyPublisher<Data, Never> { get }
}

extension DependencyValues {

    public struct ClientKey: TestDependencyKey {

        public static let testValue: Client = ClientMock()
    }

    public var client: Client {

        get {
            self[ClientKey.self]
        }
        set {
            self[ClientKey.self] = newValue
        }
    }
}

struct ClientMock: Client {

    func start(
        peripheralID: UUID,
        serviceID: CBUUID,
        rxID: CBUUID,
        txID: CBUUID
    ) -> AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
    
    func stop() {

    }
    

    var input: PassthroughSubject<Data, Never> = .init()
    var output: AnyPublisher<Data, Never> = PassthroughSubject<Data, Never>()
        .eraseToAnyPublisher()
}
