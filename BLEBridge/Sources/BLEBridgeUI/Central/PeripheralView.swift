
import Central
import ComposableArchitecture
import SwiftUI

struct PeripheralView: View {

    let store: StoreOf<Peripheral>

    var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in

            ZStack {
                List(
                    viewStore.services,
                    id: \.id,
                    selection: viewStore.binding(get: \.selected,
                                                 send: Peripheral.Action.selectService),
                    rowContent: ServiceListItemView.init
                )
                .listStyle(.plain)
                if viewStore.isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(.linear)
                            .frame(height: 1)
                        Spacer()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Text("peripheral_view.toolbar.services.title".localized())
                        .font(.headline)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
    }
}

extension PeripheralView {

    struct ViewState: Equatable {

        var isLoading: Bool
        let selected: Service.State.ID?
        var services: [Service.State]

        init(state: Peripheral.State) {

            switch (state.serviceDiscover, state.connection) {
            case (.discovering, _), (_, .connecting):
                isLoading = true
            default:
                isLoading = false
            }

            services = state.services.elements
            selected = state.selected
        }
    }
}
