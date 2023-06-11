
import Combine
import ComposableArchitecture
import Foundation

public struct Discover: ReducerProtocol {

    @Dependency(\.peripheralsDiscoverer) public var peripheralsDiscoverer
    @Dependency(\.mainQueue) public var mainQueue

    public init() {}

    public struct State: Equatable {


        public init() {

        }

        public var scan: Scan.State = .idle
        public var peripherals: IdentifiedArrayOf<Peripheral.State> = .init()
        public var selected: Peripheral.State.ID? = nil
        public var selectedPeripheral: Peripheral.State? {

            guard let id = selected else {
                return nil
            }
            return peripherals[id: id]
        }
    }

    public enum Action: Equatable {

        case setup
        case scan(Scan.Action)
        case peripheral(id: Peripheral.State.ID, action: Peripheral.Action)
        case discovered([DiscoveredPeripheral])
        case select(Peripheral.State.ID?)
        case selectedPeripheral(Peripheral.Action)
    }

    public var body: some ReducerProtocolOf<Discover> {

        Scope(state: \.scan, action: /Action.scan, child: {
            Scan.init()
        })

        .forEach(\.peripherals, action: /Action.peripheral, element: Peripheral.init)

        Reduce { state, action in

            switch action {
            case .setup:
                return .send(.scan(.setup))
            case .scan(.started):
                return EffectTask.publisher {
                    peripheralsDiscoverer.peripherals
                        .collect(.byTime(DispatchQueue.global(qos: .utility), .milliseconds(500)))
                        .map { discovered in
                            Action.discovered(discovered.map { DiscoveredPeripheral.init(id: $0.id, name: $0.name, rssi: $0.rssi) })
                        }
                        .receive(on: mainQueue)
                }
            case let .discovered(discovered):
                for d in discovered {
                    if state.peripherals[id: d.id] != nil {
                        state.peripherals[id: d.id]?.RSSI = d.rssi
                    } else {
                        state.peripherals.append(.init(id: d.id, name: d.name, RSSI: d.rssi))
                    }
                }
            case .select(let id) where state.selected != id:
                state.selected = id
                guard let id else { break }
                return EffectTask.concatenate(
                    EffectTask.run {
                        await $0(.scan(.stop))
                    },
                    EffectTask.run {
                        await $0(.peripheral(id: id, action: .connection(.connect)))
                    }
                )
            case .peripheral(id: let id, action: .connection(.connect)):
                return EffectTask.run {
                    await $0(.select(id))
                }
            case .selectedPeripheral(let action):
                guard let id = state.selected else {
                    break
                }
                return EffectTask.run {
                    await $0(.peripheral(id: id, action: action))
                }
            default:
                break
            }
            return .none
        }
    }
}

public extension Discover {

    struct DiscoveredPeripheral: Identifiable, Equatable {

        public let id: UUID
        public let name: String?
        public let rssi: Int

        public init(id: UUID, name: String?, rssi: Int) {
            self.id = id
            self.name = name
            self.rssi = rssi
        }
    }
}

public protocol PeripheralsDiscoverer {

    var peripherals: AnyPublisher<(id: UUID, name: String?, rssi: Int), Never> { get }
}

extension DependencyValues {

    public struct PeripheralsDiscovererKey: TestDependencyKey {

        public static let testValue: PeripheralsDiscoverer = PeripheralsDiscovererMock()
    }

    public var peripheralsDiscoverer: PeripheralsDiscoverer {

        get {
            self[PeripheralsDiscovererKey.self]
        }
        set {
            self[PeripheralsDiscovererKey.self] = newValue
        }
    }
}

struct PeripheralsDiscovererMock: PeripheralsDiscoverer {

    var peripherals: AnyPublisher<(id: UUID, name: String?, rssi: Int), Never> {

        PassthroughSubject<(id: UUID, name: String?, rssi: Int), Never>().eraseToAnyPublisher()
    }
}
