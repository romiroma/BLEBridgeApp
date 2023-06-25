
import Combine
import ComposableArchitecture
import Foundation
import Network

public struct ServerPublisher: ReducerProtocol {

    @Dependency(\.server) var server
    @Dependency(\.mainQueue) var mainQueue

    public init() {

    }

    public enum PublishProtocol: String, CaseIterable, Identifiable, Codable {
        
        public var id: String {
            self.rawValue
        }

        case tcp
        case udp
    }

    public struct State: Equatable {

        public var port: Result<UInt16, PortError>? = .success(40404)
        public var isRunning: Bool = false
        public var publishProtocol: PublishProtocol = .tcp
        public var publishProtocols: [PublishProtocol] = PublishProtocol.allCases
        public init() {
            
        }
    }

    public enum Action: Equatable, Codable {

        case updatePort(String)
        case start
        case started
        case startFailure(String)
        case stop
        case didStop
        case BLEToBridge(Data)
        case bridgeToBLE(Data)
        case setProtocol(PublishProtocol)
    }

    public enum PortError: Swift.Error, Equatable {

        case wrongPortInput(String)
        case valueOutOfRange(Int)
    }

    enum CancelID {
        case start
    }

    public var body: some ReducerProtocol<State, Action> {

        PortInputValidator()

        Reduce { state, action in

            switch action {
            case .start:
                guard case .success(let port) = state.port else {
                    break
                }
                let networkParameters = state.publishProtocol

                return EffectTask.merge(
                    EffectTask.run {
                        await $0(.started)
                    },
                    EffectTask.publisher {
                        do {
                            return try server.start(networkParameters, port: port)
                                .map(Action.bridgeToBLE)
                                .eraseToAnyPublisher()
                                .receive(on: mainQueue)
                        } catch {
                            return Just(
                                Action.startFailure(error.localizedDescription)
                            )
                            .eraseToAnyPublisher()
                            .receive(on: mainQueue)
                        }
                    }
                ).cancellable(id: CancelID.start)
            case .started:
                state.isRunning = true
            case .BLEToBridge(let data):
                server.input.send(data)
            case .bridgeToBLE(let data):
//                client.input.send(data)
                break
            case .stop:
                return EffectTask.concatenate(
                    EffectTask.cancel(id: CancelID.start),
                    EffectTask.run {
                        server.stop()
                        await $0(.didStop)
                    }
                )
            case .didStop:
                state.isRunning = false
            case .startFailure:
                state.isRunning = false
            case .setProtocol(let publishProtocol):
                state.publishProtocol = publishProtocol
            default:
                break
            }
            return .none
        }
    }
}

private extension UInt16 {

    static var defaultPort: UInt16 = 40404
}



public protocol Server {

    var input: PassthroughSubject<Data, Never> { get }
    func start(_ publishProtocol: ServerPublisher.PublishProtocol, port: UInt16) throws -> AnyPublisher<Data, Never>
    func stop()
}

extension DependencyValues {

    public struct ServerKey: TestDependencyKey {

        public static let testValue: Server = ServerMock()
    }

    public var server: Server {

        get {
            self[ServerKey.self]
        }
        set {
            self[ServerKey.self] = newValue
        }
    }
}

struct ServerMock: Server {

    var input: PassthroughSubject<Data, Never> = .init()

    func start(_ publishProtocol: ServerPublisher.PublishProtocol, port: UInt16) -> AnyPublisher<Data, Never> {
        return PassthroughSubject<Data, Never>()
            .eraseToAnyPublisher()
    }

    func stop() {

    }
}
