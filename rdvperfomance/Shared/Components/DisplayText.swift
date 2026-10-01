import SwiftUI

enum DisplayText {
    case localized(LocalizedStringKey)
    case verbatim(String)

    @ViewBuilder
    func view() -> some View {
        switch self {
        case let .localized(key):
            Text(key)
        case let .verbatim(value):
            Text(value)
        }
    }
}
