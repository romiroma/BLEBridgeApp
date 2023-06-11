
import Central
import ComposableArchitecture
import SwiftUI

struct ScanToggleView: View {

    let store: StoreOf<Scan>

    var body: some View {

        WithViewStore(store, observe: ToggleViewState.init) { viewStore in

            HStack {
                Text(viewStore.title)
                Spacer()
                Toggle(
                    "",
                    isOn: .init(
                        get: {
                            viewStore.isOn
                        },
                        set: {
                            viewStore.send($0 ? .start : .stop)

                        }
                    )
                )
                .toggleStyle(.switch)
                .disabled(!viewStore.isEnabled)
            }
        }
    }
}

private extension ToggleViewState {

    init(_ state: Scan.State) {

        switch state {
        case .idle:
            title = "scan_toggle_view.title.idle".localized()
            isOn = false
            isEnabled = true
        case .running:
            title = "scan_toggle_view.title.running".localized()
            isOn = true
            isEnabled = true
        case .starting:
            title = "scan_toggle_view.title.starting".localized()
            isOn = true
            isEnabled = false
        case .stopping:
            title = "scan_toggle_view.title.stopping".lowercased()
            isOn = false
            isEnabled = false
        }
    }
}
