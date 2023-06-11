
import SwiftUI

struct StatusView: View {

    let text: String

    var body: some View {
        Text(text)
            .padding(8)
            .frame(maxWidth: .infinity)
            .border(SeparatorShapeStyle(), width: 1)
            .background(Material.ultraThickMaterial)
    }
}
