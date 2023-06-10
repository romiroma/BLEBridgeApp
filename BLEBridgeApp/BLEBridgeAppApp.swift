
import BLEBridge
import BLEBridgeLive
import BLEBridgeUI
import Central
import ComposableArchitecture
import SwiftUI

@main
struct BLEBridgeAppApp: App {

    let store: StoreOf<BLEBridge> = .live()

    var body: some Scene {

        BLEBridgeScene(store: .live())
    }
}
