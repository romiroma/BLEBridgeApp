
import ComposableArchitecture
import Foundation
import NetworkPublisher


import ComposableArchitecture

public struct Log: ReducerProtocol {

    public struct State: Equatable {

        public var bleToBridge: Measurement<UnitInformationStorage>
        public var bridgeToBLE: Measurement<UnitInformationStorage>

        init() {
            bleToBridge = .init(value: 0, unit: .bytes)
            bridgeToBLE = .init(value: 0, unit: .bytes)
        }
    }

    public enum Action: Equatable, Codable {

        case append(ServerPublisher.Action)
    }

    public var body: some ReducerProtocol<State, Action> {

        Reduce { state, action in

            switch action {
            case .append(.start):
                state.bleToBridge.value = 0
                state.bridgeToBLE.value = 0
            case .append(.BLEToBridge(let data)):
                state.bleToBridge.value += .init(data.count)
            case .append(.bridgeToBLE(let data)):
                state.bridgeToBLE.value += .init(data.count)
            default:
                break
            }

            return .none
        }
    }
}

