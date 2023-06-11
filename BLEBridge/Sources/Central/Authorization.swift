
import Combine
import ComposableArchitecture
import CoreBluetooth


public struct Authorization: ReducerProtocol {

    @Dependency(\.authorizationProvider) public var authorizationProvider

    public typealias State = CBManagerAuthorization

    public enum Action: Equatable {

        case request
        case centralAuthorization(CBManagerAuthorization)
        case openSettings
    }

    public var body: some ReducerProtocolOf<Authorization> {

        Reduce { state, action in

            switch action {
            case .request where state == .notDetermined:
                return EffectTask.run { send in
                    for try await current in authorizationProvider.authorization.values {
                        await send(.centralAuthorization(current))
                    }
                }
            case .centralAuthorization(let update):
                state = update
            case .openSettings:
                assertionFailure("Not implemented")
            default:
                break
            }
            return .none
        }
    }
}

public protocol AuthorizationProvider {

    var authorization: AnyPublisher<CBManagerAuthorization, Never> { get }
}

extension DependencyValues {

    public struct AuthorizationProviderKey: TestDependencyKey {

        public static let testValue: AuthorizationProvider = AuthorizationProviderMock()
    }

    public var authorizationProvider: AuthorizationProvider {

        get {
            self[AuthorizationProviderKey.self]
        }
        set {
            self[AuthorizationProviderKey.self] = newValue
        }
    }
}

struct AuthorizationProviderMock: AuthorizationProvider {

    let authorization: AnyPublisher<CBManagerAuthorization, Never> = Just(.allowedAlways).eraseToAnyPublisher()
}
