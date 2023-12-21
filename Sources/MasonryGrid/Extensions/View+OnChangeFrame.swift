
import SwiftUI

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

extension View {
    func onChangeFrame(_ block: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader {
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: $0.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: block)
    }
}
