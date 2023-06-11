
import Central
import ComposableArchitecture
import SwiftUI

struct PeripheralConnectionToggleView: View {

    let store: StoreOf<Peripheral.Connection>

    var body: some View {

        WithViewStore(store, observe: ToggleViewState.init) { viewStore in

            HStack {
                Text(viewStore.title)
                Spacer().frame(width: 8)
                Toggle(
                    "",
                    isOn: .init(
                        get: {
                            viewStore.isOn
                        },
                        set: {
                            viewStore.send($0 ? .connect : .disconnect)

                        }
                    )
                )
                .toggleStyle(.switch)
                .disabled(!viewStore.isEnabled)
            }
        }
    }
}

extension ToggleViewState {

    init(_ state: Peripheral.Connection.State) {

        switch state {
        case .disconnected:
            title = "Connect"
            isOn = false
            isEnabled = true
        case .connected:
            title = "Connected"
            isOn = true
            isEnabled = true
        case .connecting:
            title = "Connecting..."
            isOn = true
            isEnabled = false
        case .disconnecting:
            title = "Disconnecting..."
            isOn = false
            isEnabled = false
        }
    }
}
