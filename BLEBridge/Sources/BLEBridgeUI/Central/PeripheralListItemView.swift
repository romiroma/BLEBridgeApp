
import Central
import ComposableArchitecture
import SwiftUI

struct PeripheralListItemView: View {

    let state: ViewState
    let connectionAction: (Peripheral.Connection.Action) -> Void

    var body: some View {

        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(state.title)
                    .font(.headline)
                    .scaledToFit()
                    .minimumScaleFactor(0.5)
                HStack(spacing: 8) {
                    VStack(alignment: .leading) {
                        Text(state.rssi)
                            .font(.subheadline)
                    }
                    Spacer()
                    ConnectionView(state: state.connection, send: connectionAction)
                }
            }
        }
        .padding(8)
    }
}


extension PeripheralListItemView {

    struct ViewState: Equatable {

        let id: Peripheral.State.ID
        let title: String
        let rssi: String
        let connection: Peripheral.Connection.State

        init(state: Peripheral.State) {

            id = state.id
            title = state.name ?? "peripheral_list_item_view.title".localized()
            rssi = "RSSI: \(state.RSSI)"
            connection = state.connection
        }
    }
}

extension View {

    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

private extension PeripheralListItemView {

    struct ConnectionView: View {

        let state: Peripheral.Connection.State
        let viewState: ToggleViewState
        let send: (Peripheral.Connection.Action) -> Void

        init(state: Peripheral.Connection.State, send: @escaping (Peripheral.Connection.Action) -> Void) {
            self.state = state
            self.viewState = .init(state)
            self.send = send
        }

        var body: some View {

            Toggle("", isOn: .init(get: { viewState.isOn },
                                   set: { send($0 ? .connect : .disconnect) }))
            .toggleStyle(.switch)
            .disabled(!viewState.isEnabled)
        }
    }
}
