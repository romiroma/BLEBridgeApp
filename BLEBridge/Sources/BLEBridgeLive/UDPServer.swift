//
//import Combine
//import Foundation
//import Network
//import NetworkPublisher
//
//
//class UDPServer: NetworkPublisher.Server {
//
//    enum Error: Swift.Error {
//        case coudntCreatePort(UInt16)
//    }
//
//    private var connection: NWConnection!
//
//    init() {
//
//    }
//
//    let input: PassthroughSubject<Data, Never> = .init()
//    private var inputCancellable: AnyCancellable?
//    private let output: PassthroughSubject<Data, Swift.Never> = .init()
//
//    func start(port: UInt16) -> AnyPublisher<Data, Swift.Never> {
//
//        guard let nwPort = NWEndpoint.Port.init(rawValue: port) else {
//            return Fail(error: Error.coudntCreatePort(port)).eraseToAnyPublisher()
//        }
//        connection = NWConnection(host: "127.0.0.1", port: nwPort, using: .udp)
//
//        inputCancellable = input.sink(receiveValue: { [unowned self] in
//            send(payload: $0)
//        })
//
//        connection.viabilityUpdateHandler
//        connection.start(queue: .global(qos: .userInitiated))
//        return output.eraseToAnyPublisher()
//    }
//
//    func send(payload: Data) {
//
//        guard let connection else {
//            return
//        }
//        connection.send(content: payload, completion: .contentProcessed({ sendError in
//            if let error = sendError {
//                print("Unable to process and send the data: \(error)")
//            } else {
//                print("Data has been sent")
//                self.receive()
//            }
//        }))
//    }
//
//    func receive() {
//        connection.receiveMessage { (data, context, isComplete, error) in
//            guard let data else { return }
//            print("Received message: " + String(decoding: data, as: UTF8.self))
//            self.output.send(data)
//        }
//    }
//
//    func stop() {
//
//    }
//}
