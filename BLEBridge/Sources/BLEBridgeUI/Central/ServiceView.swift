
import Central
import ComposableArchitecture
import SwiftUI

struct ServiceView: View {

    let store: StoreOf<Service>

    var body: some View {

        WithViewStore(store, observe: ViewState.init) { viewStore in

            ZStack {
                VStack {
                    List {
                        ForEachStore(
                            store.scope(
                                state: \.characteristics,
                                action: Service.Action.characteristic
                            ),
                            content: CharacteristicView.init)
                    }
                    .listStyle(.inset)
                }
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
                    Text("service_view.toolbar.characteristics.title".localized())
                        .font(.headline)
                        .padding([.leading], 12)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

extension ServiceView {

    struct ViewState: Equatable {

        var isLoading: Bool

        init(state: Service.State) {

            switch (state.characteristicDiscover, state.serviceDiscover) {
            case (.discovering, _), (_, .discovering):
                isLoading = true
            default:
                isLoading = false
            }
        }
    }
}
