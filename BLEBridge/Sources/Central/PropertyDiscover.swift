
import ComposableArchitecture

public struct PropertyDiscover<Discovered: Hashable & Equatable>: ReducerProtocol {

    public enum State: Hashable, Equatable {

        case idle(Discovered)
        case discovering
    }

    public enum Action: Hashable, Equatable {
        case discover
        case discovered(Discovered)
    }

    public var body: some ReducerProtocolOf<PropertyDiscover> {

        Reduce { state, action in

            switch action {
            case .discover:
                state = .discovering
            case .discovered(let discovered):
                state = .idle(discovered)
            }
            return .none
        }
    }
}
