
import Central
import ComposableArchitecture
import SwiftUI

struct AuthorizationView: View {

    let store: StoreOf<Authorization>

    var body: some View {

        WithViewStore(store) { viewStore in

            switch viewStore.state {
            case .notDetermined:
                VStack {
                    Spacer()
                    Image(systemName: "questionmark.circle.fill")
                        .font(.headline)
                    Spacer()
                        .frame(height: 8)
                }
            case .allowedAlways:
                EmptyView()
            case .denied, .restricted:
                VStack {
                    Spacer()
                    Image(systemName: "xmark.circle")
                        .font(.headline)
                    Spacer()
                        .frame(height: 8)
                    Text("authorization_view.denied.title".localized())
                    Spacer()
                }
                
            @unknown default:
                EmptyView()
            }
        }
    }
}
