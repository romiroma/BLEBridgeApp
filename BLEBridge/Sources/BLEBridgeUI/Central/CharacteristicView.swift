
import Central
import ComposableArchitecture
import SwiftUI

struct CharacteristicView: View {

    let store: StoreOf<Characteristic>

    var body: some View {

        WithViewStore(store) { viewStore in
            VStack {
                HStack {
                    Text(viewStore.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.all, 4)
                    Spacer()
                    Divider()
                    VStack {
                        Picker(
                            "",
                            selection: viewStore.binding(
                                get: \.property.usage,
                                send: {
                                    .property(.use($0))
                                }
                            )
                        ) {
                            ForEach(viewStore.property.canBeUsedFor) { usage in
                                Text(usage.title).tag(usage)
                            }
                        }
                        .pickerStyle(.radioGroup)
                    }
                }
            }
        }
    }
}

private extension Optional where Wrapped == Characteristic.Property.Usage {

    var title: String {

        switch self {
        case .none:
            return "none"
        case .some(let u):
            return u.title
        }
    }
}
private extension Characteristic.Property.Usage {

    var title: String {

        switch self {
        case .notify:
            return "Rx"
        case .writeWithoutResponse:
            return "Tx"
        default:
            assertionFailure("Uncovered case \(self)")
            return ""
        }
    }
}
