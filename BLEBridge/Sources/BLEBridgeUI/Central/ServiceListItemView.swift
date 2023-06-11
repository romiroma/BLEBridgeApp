
import Central
import ComposableArchitecture
import SwiftUI

struct ServiceListItemView: View {

    let state: Service.State

    var body: some View {

        HStack {
            VStack(alignment: .leading) {
                Text(state.name)
                    .font(.headline)
            }
            Spacer()
        }
        .padding(.all, 8)
    }
}
