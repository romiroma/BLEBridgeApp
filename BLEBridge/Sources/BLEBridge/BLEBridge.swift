
import BLEPublish
import Central
import ComposableArchitecture
import CoreBluetooth
import Foundation

public struct BLEBridge: ReducerProtocol {

    public init() {}

    public struct State: Equatable {

        public var central: Central.State = .initial
        public var publish: Publish.State? = nil

        public init() {}
    }

    public enum Action: Equatable {

        case setup
        case central(Central.Action)
        case publish(Publish.Action)
    }

    public var body: some ReducerProtocolOf<BLEBridge> {

        Scope(state: \.central, action: /Action.central, child: Central.init)

            .ifLet(\.publish, action: /Action.publish, then: Publish.init)

        ForwardToPublish()

        Reduce { state, action in
            switch action {
            case .setup:
                return .send(.central(.setup))
            case .central(
                .discover(
                    .peripheral(
                        let peripheralID,
                        .services(
                            let serviceID,
                            .checkPublish
                        )
                    )
                )
            ):
                guard case .discover(let discoverState) = state.central,
                      let peripheral = discoverState.peripherals[id: peripheralID],
                      let service = peripheral.services[id: serviceID] else {
                    state.publish = nil
                    break
                }

                state.publish = service.canPublish ? .init() : nil
            case .publish(.server(.started)):
                guard case .discover(let discoverState) = state.central else {
                    break
                }
                for peripheral in discoverState.peripherals.elements {
                    for service in peripheral.services where service.canPublish {
                        return .send(
                            .central(
                                .discover(
                                    .peripheral(
                                        id: peripheral.id,
                                        action: .services(
                                            id: service.id,
                                            action: .publish
                                        )
                                    )
                                )
                            )
                        )
                    }
                }
            case .central(
                .discover(
                    .peripheral(
                        id: _,
                        action: .didRead(let data)
                    )
                )
            ):
                return .send(
                    .publish(
                        .server(
                            .BLEToBridge(data)
                        )
                    )
                )
            case .publish(.server(.bridgeToBLE(let data))):
                return .send(
                    .central(.discover(.selectedPeripheral(.write(data))))
                )
            case .publish(.server(.didStop)):
                return .send(.central(.discover(.selectedPeripheral(.stopDataExchange))))
            case .central(.stateUpdate(.poweredOn)):
                state.publish = nil
            default:
                break
            }
            return .none
        }
    }
}

struct ForwardToPublish: ReducerProtocol {

    var body: some ReducerProtocol<BLEBridge.State, BLEBridge.Action> {

        Reduce { state, action in

            guard state.publish != nil else {
                return .none
            }

            switch action {
            case .central(
                .discover(
                    .selectedPeripheral(let action)
                )
            ):
                return .send(.publish(.peripheral(action)))
            case .central(
                .discover(
                    .peripheral(id: let peripheralID, action: let action)
                )
            ):
                guard case .discover(let discoverState) = state.central else {
                    break
                }
                guard discoverState.selected == peripheralID else {
                    break
                }
                return .send(.publish(.peripheral(action)))
            case .central(.stateUpdate(.poweredOff)):
                return .send(.publish(.server(.stop)))
            default:
                break
            }
            return .none
        }
    }
}
