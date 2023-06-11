
import Central
import ComposableArchitecture
import NetworkPublisher

public struct Publish: ReducerProtocol {

    public init() {}

    public struct State: Equatable {

        public var server: ServerPublisher.State = .init()
        public var log: Log.State = .init()

        public init() {}
    }

    public enum Action: Equatable {

        case peripheral(Peripheral.Action)
        case server(ServerPublisher.Action)
        case log(Log.Action)
    }

    public var body: some ReducerProtocol<State, Action> {

        Reduce { state, action in

            switch action {
            default:
                break
            }

            return .none
        }

        Scope(state: \.server, action: /Publish.Action.server, child: ServerPublisher.init)

        Scope(state: \.log, action: /Publish.Action.log, child: Log.init)

        Reduce { state, action in

            switch action {
            case .server(let action):
                return .send(.log(.append(action)))
            case .peripheral(.connection(.updateConection(isConnected: false))):
                return .send(.server(.stop))
            default:
                return .none
            }
        }
    }
}

