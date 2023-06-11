
import BLEPublish
import ComposableArchitecture
import SwiftUI

struct PublishView: View {

    let store: StoreOf<Publish>

    var body: some View {

        HSplitView {

            ServerView(
                store: store.scope(
                    state: \.server,
                    action: Publish.Action.server
                )
            )
            .frame(minWidth: 260, idealWidth: 260, maxWidth: .infinity)

            LogView(
                store: store.scope(
                    state: \.log,
                    action: Publish.Action.log
                )
            )
                .frame(minHeight: 260)
            .frame(minWidth: 260, idealWidth: 260, maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: 120)
    }
}
