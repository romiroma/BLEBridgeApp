
import Central
import ComposableArchitecture
import SwiftUI

struct DiscoverView: View {

    let store: StoreOf<Discover>
    let selectedPeripheralStore: Store<Peripheral.State?, Peripheral.Action>
    @State var userSelectedNavigationSplitViewVisibility: NavigationSplitViewVisibility? = nil

    init(store: StoreOf<Discover>) {
        self.store = store
        self.selectedPeripheralStore = store.scope(state: \.selectedPeripheral,
                                                   action: Discover.Action.selectedPeripheral)
    }

    var body: some View {

        NavigationSplitView(sidebar: {
            PeripheralListView(store: store)
                .navigationSplitViewColumnWidth(min: 260, ideal: 300)
                .padding(.zero)
        }, content: {
            IfLetStore(
                selectedPeripheralStore,
                then: PeripheralView.init
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 300)
        }, detail: {
            IfLetStore(
                selectedPeripheralStore.scope(
                    state: \.?.selectedService,
                    action: Peripheral.Action.selectedService
                ),
                then: ServiceView.init
            )
            .navigationSplitViewColumnWidth(min: 360, ideal: 404)
        })
        .padding(.zero)
        .navigationSplitViewStyle(.prominentDetail)
    }
}

private extension NavigationSplitViewVisibility {

    init(state: Discover.State) {

        switch state.scan {
        case .running, .starting, .stopping:
            self = .all
            return
        default: break
        }

        if state.selectedPeripheral?.selectedService != nil {
            self = .doubleColumn
        } else {
            self = .all
        }
    }
}
