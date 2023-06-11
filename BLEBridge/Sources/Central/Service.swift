
import Combine
import ComposableArchitecture
import CoreBluetooth
import Foundation

public struct Service: ReducerProtocol {

    @Dependency(\.servicesDiscoverer) var servicesDiscoverer
    @Dependency(\.mainQueue) var mainQueue

    public struct State: Identifiable, Hashable, Equatable {

        public let id: CBUUID
        public let name: String
        public var characteristics: IdentifiedArrayOf<Characteristic.State> = .init()
        public var characteristicDiscover: Characteristic.Discover.State = .idle([])
        public var includedServices: IdentifiedArrayOf<Service.Included.State> = .init()
        public var serviceDiscover: Service.Discover.State = .idle([])

        public var tx: CBUUID?
        public var rx: CBUUID?

        public var canPublish: Bool {
            tx != nil && rx != nil
        }
    }

    public enum Action: Equatable {

        case characteristic(id: Characteristic.State.ID, action: Characteristic.Action)
        case characteristicDiscover(Characteristic.Discover.Action)
        case includedServices(id: Service.Included.State.ID, action: Service.Included.Action)
        case serviceDiscover(Service.Discover.Action)
        case activate
        case checkPublish
        case publish
    }

    public var body: some ReducerProtocolOf<Service> {

        Scope(state: \.serviceDiscover, action: /Service.Action.serviceDiscover, child: Service.Discover.init)
            .forEach(\.characteristics, action: /Action.characteristic, element: Characteristic.init)
            .forEach(\.includedServices, action: /Action.includedServices, element: Service.Included.init)
        Scope(state: \.characteristicDiscover, action: /Service.Action.characteristicDiscover, child: Characteristic.Discover.init)
        Reduce { state, action in

            switch action {
            case .characteristicDiscover(.discovered(let characteristics)):
                state.characteristics = .init(
                    uniqueElements: characteristics.map { Characteristic.State.init(id: $0.id, name: $0.name, property: .init($0.property)) }
                )
            case .serviceDiscover(.discover) where state.serviceDiscover == .discovering:
                let id = state.id
                return EffectTask.publisher {
                    servicesDiscoverer.includedServices(ofServiceWithID: id)
                        .map { Action.serviceDiscover(.discovered($0)) }
                        .receive(on: mainQueue)
                }
            case .characteristicDiscover(.discover) where state.characteristicDiscover == .discovering:
                let id = state.id
                return EffectTask.publisher {
                    servicesDiscoverer.characteristics(ofServiceWithID: id)
                        .map { Action.characteristicDiscover(.discovered($0)) }
                        .receive(on: mainQueue)
                }
            case .activate:
                return EffectTask.concatenate(
                    .init(value: Action.serviceDiscover(.discover)),
                    .init(value: Action.characteristicDiscover(.discover))
                )
            case .characteristic(
                    let characteristicID,
                    .property(.use(let usage))
                ):
                var effects = [EffectTask<Action>]()
                if let usage {
                    for charateristic in state.characteristics where
                    charateristic.id != characteristicID && charateristic.property.usage == usage {
                        effects.append(.send(.characteristic(
                            id: charateristic.id,
                            action: .property(.use(.none))
                        )))
                    }
                }
                effects.append(.send(.checkPublish))
                return EffectTask.merge(effects)
            case .checkPublish:
                state.rx = nil
                state.tx = nil
                for characteristic in state.characteristics {
                    guard let usage = characteristic.property.usage else { continue }
                    switch usage {
                    case .writeWithoutResponse:
                        state.tx = characteristic.id
                    case .notify:
                        state.rx = characteristic.id
                    default:
                        break
                    }
                }
            default:
                break
            }
            return .none
        }
    }
}
