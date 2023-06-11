
import Combine
import ComposableArchitecture
import CoreBluetooth
import Dispatch

public struct Central: ReducerProtocol {

    public init() {}

    @Dependency(\.centralStateProvider) public var centralStateProvider

    public enum State: Equatable {

        case initial
        case resetting
        case unsupported
        case poweredOff
        case poweredOn
        case authorization(Authorization.State)
        case discover(Discover.State)
    }

    public enum Action: Equatable {

        case setup
        case stateUpdate(State.Update)
        case authorization(Authorization.Action)
        case discover(Discover.Action)
    }

    public var body: some ReducerProtocolOf<Central> {

        Reduce { state, action in
            return .none
        }
        .ifCaseLet(/State.authorization,
                    action: /Action.authorization,
                    then: Authorization.init)
        .ifCaseLet(/State.discover,
                    action: /Action.discover,
                    then: Discover.init)
        Reduce { state, action in

            switch action {
            case .setup where state == .initial:
                return EffectTask.run { send in
                    for try await centralState in centralStateProvider.state.values {
                        await send(.stateUpdate(centralState))
                    }
                }
            case .stateUpdate(let stateUpdate):
                switch stateUpdate {
                case .poweredOn:
                    state = .authorization(.notDetermined)
                    return EffectTask.run { send in
                        await send(.setup)
                    }
                case .unauthorized:
                    state = .authorization(.denied)
                    return .none
                default:
                    state = .init(stateUpdate)
                    return .none
                }
            case .setup where state == .authorization(.notDetermined):
                return .send(.authorization(.request))
            case .authorization(.centralAuthorization(.allowedAlways)):
                state = .discover(.init())
                return .send(.discover(.setup))
            default:
                return .none
            }
        }
    }
}

extension Central.State {

    public enum Update {

        case resetting
        case unsupported
        case poweredOff
        case poweredOn
        case unauthorized
    }

    init(_ update: Update) {
        switch update {
        case .resetting:
            self = .resetting
        case .unsupported:
            self = .unsupported
        case .poweredOff:
            self = .poweredOff
        case .poweredOn:
            self = .poweredOn
        case .unauthorized:
            self = .authorization(.notDetermined)
        }
    }
}

public protocol CentralStateProvider {

    var state: AnyPublisher<Central.State.Update, Never> { get }
}

extension DependencyValues {

    public struct CentralStateProviderKey: TestDependencyKey {

        public static let testValue: CentralStateProvider = CentralStateProviderMock()
    }

    public var centralStateProvider: CentralStateProvider {

        get {
            self[CentralStateProviderKey.self]
        }
        set {
            self[CentralStateProviderKey.self] = newValue
        }
    }
}

struct CentralStateProviderMock: CentralStateProvider {

    var state: AnyPublisher<Central.State.Update, Never> = Just(.poweredOn).eraseToAnyPublisher()    
}
