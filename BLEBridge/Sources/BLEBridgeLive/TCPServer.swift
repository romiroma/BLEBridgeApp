
import Foundation
import Combine
import ComposableArchitecture
import Network
import NetworkPublisher

extension DependencyValues.ServerKey: DependencyKey {

    public static var liveValue: NetworkPublisher.Server = TCPServer.init()
}

@available(macOS 10.14, *)
class TCPServer: NetworkPublisher.Server {

    enum Error: Swift.Error {
        case coudntCreatePort(UInt16)
        case couldntCreateListener(Swift.Error)
    }

    private var listener: NWListener?
    private var connection: NWConnection?
    private var cancellables = Set<AnyCancellable>()

    let input: PassthroughSubject<Data, Never> = .init()
    private let output: PassthroughSubject<Data, Swift.Never> = .init()

    func start(port: UInt16) throws -> AnyPublisher<Data, Swift.Never> {
        print("Server starting...")

        guard let port = NWEndpoint.Port.init(rawValue: port) else {
            throw Error.coudntCreatePort(port)
        }

        let listener: NWListener
        do {
            listener = try NWListener(using: .tcp, on: port)
        } catch {
            throw Error.couldntCreateListener(error)
        }

        setupListener(listener)

        input.sink(receiveValue: { [unowned self] data in

            guard let connection,
                  connection.state == .ready else {
                return
            }

            connection.send(
                content: data,
                completion: .contentProcessed({ error in
//                    print("=== didSend data", data, "error:", error)
                })
            )
        }).store(in: &cancellables)

        return output.eraseToAnyPublisher()
    }

    func stop() {

        if let listener {
            listener.stateUpdateHandler = nil
            listener.newConnectionHandler = nil
            listener.cancel()
            self.listener = nil
        }
        if let connection {
            connection.cancel()
            connection.stateUpdateHandler = nil
            self.connection = nil
        }
        cancellables.removeAll()
    }

    private func setupListener(_ listener: NWListener) {

        listener.stateUpdateHandler = { [weak self] newState in

            guard let self else { return }

            switch newState {

            case .setup:
                break
            case .waiting(let error):
                break
            case .ready:
                break
            case .failed(let error):
                self.output.send(completion: .finished)
            case .cancelled:
                self.output.send(completion: .finished)
            @unknown default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in

            self?.setupConnection(connection)
        }

        listener.start(queue: .global(qos: .userInitiated))
        self.listener = listener
    }

    private func setupConnection(_ connection: NWConnection) {

        connection.stateUpdateHandler = { [weak self, weak connection] state in

            switch state {

            case .setup:
                break
            case .waiting(_):
                break
            case .preparing:
                break
            case .ready:
                guard let self, let connection else { break }
                self.receive(connection)
            case .failed(_):
                break
            case .cancelled:
                break
            @unknown default:
                break
            }
        }

        connection.start(queue: .global(qos: .userInitiated))

        self.connection = connection
    }

    private func receive(_ connection: NWConnection) {

        guard connection.state == .ready else {
            return
        }

        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: 65535
        ) { [weak self, weak connection] content, contentContext, isComplete, error in

            guard let self else { return }

            if let content {
                self.output.send(content)
            }

            if !isComplete, let connection {
                self.receive(connection)
            }
        }
    }
}
