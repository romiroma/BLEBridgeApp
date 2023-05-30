
import BLEBridge
import BLEBridgeLive
import BLEBridgeUI
import ComposableArchitecture
import SwiftUI

@main
struct BLEBridgeAppApp: App {

    let store: StoreOf<BLEBridge> = .live()

    var body: some Scene {
        WindowGroup {

            BLEBridgeView(store: store)
        }
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
    }
}
