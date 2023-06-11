
import ComposableArchitecture
import CoreBluetooth
import Foundation

public struct Characteristic: ReducerProtocol {

    public struct State: Identifiable, Hashable, Equatable {

        public var id: CBUUID
        public var name: String

        public var property: Property.State
    }

    public enum Action: Equatable {
        case discover
        case property(Property.Action)
    }

    public var body: some ReducerProtocolOf<Characteristic> {

        Scope(state: \.property, action: /Characteristic.Action.property, child: Property.init)
        Reduce { state, action in

            return .none
        }
    }
}

