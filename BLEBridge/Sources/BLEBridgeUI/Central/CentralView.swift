
import Central
import ComposableArchitecture
import SwiftUI

struct CentralView: View {

    let store: StoreOf<Central>

    var body: some View {

        SwitchStore(store) { state in
            switch state {
            case .discover:
                CaseLet(
                    state: /Central.State.discover,
                    action: Central.Action.discover,
                    then: DiscoverView.init
                )
            case .authorization:
                CaseLet(
                    state: /Central.State.authorization,
                    action: Central.Action.authorization,
                    then: AuthorizationView.init
                )
            case .initial:
                WithViewStore(store.stateless) { viewStore in
                    Text("")
                        .onAppear {
                            viewStore.send(.setup)
                        }
                }
            case .poweredOff:
                VStack {
                    Spacer()
                    Image(systemName: "power")
                        .font(.headline)
                    Spacer()
                        .frame(height: 8)
                    Text("central_view.powered_off.title".localized())
                    Spacer()
                }
            default:
                EmptyView()
            }
        }
    }
}
