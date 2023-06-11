
import ComposableArchitecture
import Combine
import Dispatch

public struct Scan: ReducerProtocol {

    @Dependency(\.centralScanner) public var centralScanner
    @Dependency(\.mainQueue) public var mainQueue

    public enum State: Equatable {

        case idle
        case starting
        case running
        case stopping
    }

    public enum Action: Equatable {

        case setup
        case start
        case started
        case stop
        case stopped
    }

    public var body: some ReducerProtocolOf<Scan> {

        Reduce { state, action in

            switch action {
            case .setup:
                return EffectTask.publisher {
                    centralScanner.state.map {
                        $0 ? Action.started : .stopped
                    }.receive(on: mainQueue)
                }
            case .start where state == .idle:
                state = .starting
                centralScanner.start()
            case .started:
                state = .running
            case .stopped where state != .idle:
                state = .idle
            case .stop where state == .running:
                state = .stopping
                centralScanner.stop()
            default:
                break
            }
            return .none
        }
    }
}

public protocol CentralScanner {

    func start()
    func stop()
    var state: AnyPublisher<Bool, Never> { get }
}

extension DependencyValues {

    public struct CentralScannerKey: TestDependencyKey {

        public static let testValue: CentralScanner = CentralScannerMock()
    }

    public var centralScanner: CentralScanner {

        get {
            self[CentralScannerKey.self]
        }
        set {
            self[CentralScannerKey.self] = newValue
        }
    }
}

struct CentralScannerMock: CentralScanner {

    private let output = PassthroughSubject<Bool, Never>()

    func start() {
        output.send(true)
    }

    func stop() {
        output.send(false)
    }

    var state: AnyPublisher<Bool, Never> {
        output.eraseToAnyPublisher()
    }
}
