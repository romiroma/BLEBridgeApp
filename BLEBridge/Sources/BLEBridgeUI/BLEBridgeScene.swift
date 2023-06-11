
import BLEBridge
import Central
import ComposableArchitecture
import SwiftUI
import BLEPublish

public struct BLEBridgeScene: Scene {

    let store: StoreOf<BLEBridge>

    public init(store: StoreOf<BLEBridge>) {

        self.store = store
    }

    public var body: some Scene {

        WindowGroup.init("BLEBridge", id: "BLEBridge") {

            VStack(spacing: .zero) {

                CentralView(
                    store: store.scope(
                        state: \.central,
                        action: BLEBridge.Action.central
                    )
                )
                Divider()
                IfLetStore(
                    store.scope(
                        state: \.publish,
                        action: BLEBridge.Action.publish
                    ),
                    then: PublishView.init)
                .frame(maxHeight: 120)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .monospaced()
            .controlSize(.small)
        }
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
    }
}
