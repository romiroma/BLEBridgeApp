
import ComposableArchitecture

public struct PortInputValidator: ReducerProtocol {

    public var body: some ReducerProtocolOf<ServerPublisher> {

        Reduce { state, action in

            switch action {
            case .updatePort(let input):

                if let portUInt16Value = UInt16.init(input) {
                    state.port = .success(portUInt16Value)
                } else if let portIntValue = Int.init(input) {
                    state.port = .failure(.valueOutOfRange(portIntValue))
                } else {
                    state.port = .failure(.wrongPortInput(input))
                }
            default:
                break
            }

            return .none
        }
    }
}
