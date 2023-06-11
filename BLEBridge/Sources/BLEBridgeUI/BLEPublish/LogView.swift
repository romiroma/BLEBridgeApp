
import BLEPublish
import ComposableArchitecture
import NetworkPublisher
import SwiftUI

struct LogView: View {

    let store: StoreOf<Log>

    var body: some View {

        WithViewStore(store.actionless, observe: ViewState.init) { viewStore in
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        Text("log.ble_to_bridge.title".localized())
                            .font(.headline)
                        Text(viewStore.bleToBridge)
                            .font(.headline)
                            .padding(4)
                            .background(Material.bar)
                            .cornerRadius(4)
                    }
                    Spacer()
                    Divider()
                    Spacer()
                    VStack {
                        Text("log.bridge_to_ble.title".localized())
                            .font(.headline)
                        Text(viewStore.bridgeToBLE)
                            .font(.headline)
                            .padding(4)
                            .background(Material.bar)
                            .cornerRadius(4)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

extension LogView {

    struct ViewState: Equatable {

        static let formatter: MeasurementFormatter = {
            let f = MeasurementFormatter()
            f.unitOptions = .naturalScale
            f.unitStyle = .short
            return f
        }()

        let bleToBridge: String
        let bridgeToBLE: String

        init(_ state: Log.State) {

            bleToBridge = Self.formatter.string(from: state.bleToBridge)
            bridgeToBLE = Self.formatter.string(from: state.bridgeToBLE)
        }
    }
}
