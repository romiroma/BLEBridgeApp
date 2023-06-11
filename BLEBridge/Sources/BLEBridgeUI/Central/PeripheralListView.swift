
import Central
import ComposableArchitecture
import SwiftUI

struct PeripheralListView: View {

    let store: StoreOf<Discover>

    var body: some View {

        WithViewStore(store, observe: ViewState.init) { viewStore in
            List(
                viewStore.peripherals,
                id: \.id,
                selection: viewStore.binding(
                    get: \.selected,
                    send: Discover.Action.select
                ),
                rowContent: { state in
                    PeripheralListItemView.init(state: state) { action in
                        viewStore.send(
                            .peripheral(
                                id: state.id,
                                action: .connection(action)
                            )
                        )
                    }
                }
            )
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                ScanToggleView(
                    store: store.scope(
                        state: \.scan,
                        action: Discover.Action.scan)
                )
            }
        }
    }
}

private extension PeripheralListView {

    struct ViewState: Equatable {

        let peripherals: [PeripheralListItemView.ViewState]
        let selected: Peripheral.State.ID?

        init(_ state: Discover.State) {
            peripherals = state.peripherals.map(PeripheralListItemView.ViewState.init)
            selected = state.selected
        }
    }
}
