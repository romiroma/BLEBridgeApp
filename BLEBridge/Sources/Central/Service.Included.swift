
import ComposableArchitecture
import Foundation

extension Service {

    public struct Included: ReducerProtocol {

        public struct State: Identifiable, Hashable, Equatable {

            public var id: UUID
            public var characteristics: IdentifiedArrayOf<Characteristic.State>
        }

        public enum Action: Equatable {
            
            case characteristic(id: Characteristic.State.ID, action: Characteristic.Action)
        }

        public var body: some ReducerProtocolOf<Included> {

            Reduce { state, action in

                return .none
            }
            .forEach(\.characteristics, action: /Action.characteristic, element: Characteristic.init)
        }
    }
}
