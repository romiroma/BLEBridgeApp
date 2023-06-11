
import ComposableArchitecture
import NetworkPublisher
import SwiftUI

struct ServerView: View {

    let store: StoreOf<ServerPublisher>

    var body: some View {

        WithViewStore(store, observe: ViewState.init) { viewStore in
            HStack {
                VStack {
                    HStack {
                        Text("server_view.publish.tcp_port.title".localized())
                        TextField(
                            "",
                            text: viewStore.binding(
                                get: \.port,
                                send: ServerPublisher.Action.updatePort
                            ),
                            prompt: Text("1-65535")
                        )
                    }
                    if let error = viewStore.error {
                        Text(error)
                            .foregroundColor(Color.red)
                    }
                }
                Button {
                    if viewStore.isRunning {
                        viewStore.send(.stop)
                    } else {
                        viewStore.send(.start)
                    }
                } label: {
                    if viewStore.isRunning {
                        Text("publish.button.title.stop".localized())
                    } else {
                        Text("publish.button.title.start".localized())
                    }
                }
            }
            .padding(8)
        }
    }
}

private extension ServerView {

    struct ViewState: Equatable {

        var port: String
        var error: String?
        var isButtonEnabled: Bool
        var isRunning: Bool

        init(_ state: ServerPublisher.State) {

            switch state.port {
            case .success(let port):
                self.port = "\(port)"
                self.error = nil
            case .failure(let error):
                self.port = ""
                self.error = error.localizedDescription
            case .none:
                self.port = ""
                self.error = nil
            }
            isButtonEnabled = error == nil && !port.isEmpty
            isRunning = state.isRunning
        }
    }
}

extension ServerPublisher.PortError: LocalizedError {

    var localizedDescription: String {

        switch self {
        case .valueOutOfRange(let value):
            return "Value \"\(value)\" out of range (1-65535)"
        case .wrongPortInput(let input):
            return "Value \"\(input)\" is not valid port number"
        }
    }
}
