

import ComposableArchitecture

extension Peripheral {

    public struct Connection: ReducerProtocol {

        public enum State: Equatable {

            case disconnected
            case connecting
            case connected
            case disconnecting
        }

        public enum Action: Equatable {

            case connect
            case disconnect
            case updateConection(isConnected: Bool)
        }

        public var body: some ReducerProtocolOf<Connection> {

            Reduce { state, action in

                switch action {
                case .updateConection(let isConnected):
                    state = isConnected ? .connected : .disconnected
                case .connect where state == .disconnected:
                    state = .connecting
                case .connect:
                    break
                case .disconnect:
                    state = .disconnecting
                }
                return .none
            }
        }
    }
}

