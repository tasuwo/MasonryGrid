//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

public struct HMasonryGrid<Data, Content>: View where Data: Identifiable & Hashable, Content: View {
    @State private var availableWidth: CGFloat = 0
    @State private var widths: [Data: CGFloat] = [:]

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var data: [Data]
    private let width: (Data) -> CGFloat
    private let content: (Data) -> Content
    private let lineSpacing: CGFloat
    private let contentSpacing: CGFloat

    public init(_ data: [Data],
                lineSpacing: CGFloat = 8,
                contentSpacing: CGFloat = 8,
                width: @escaping (Data) -> CGFloat,
                @ViewBuilder content: @escaping (Data) -> Content) {
        self.data = data
        self.lineSpacing = lineSpacing
        self.contentSpacing = contentSpacing
        self.width = width
        self.content = content
    }

    public var body: some View {
        LazyVStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(calcRows(), id: \.self) { items in
                LazyHStack(spacing: contentSpacing) {
                    ForEach(items) { item in
                        content(item)
                            .frame(maxWidth: availableWidth)
                    }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .background(
            Color.clear
                .frame(height: 0)
                .onChangeFrame { frame in
                    widths = [:]
                    availableWidth = frame.width
                }
        )
        .onChange(of: dynamicTypeSize) { _ in
            widths = [:]
        }
    }
}

extension HMasonryGrid {
    private func calcRows() -> [[Data]] {
        var rows: [[Data]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth

        for d in data {
            let contentWidth: CGFloat = widths[d] ?? min(width(d), availableWidth)
            if rows[currentRow].isEmpty {
                rows[currentRow].append(d)
                remainingWidth -= contentWidth
            } else if remainingWidth - (contentWidth + contentSpacing) >= 0 {
                rows[currentRow].append(d)
                remainingWidth -= (contentWidth + contentSpacing)
            } else {
                currentRow += 1
                rows.append([d])
                remainingWidth = availableWidth
                remainingWidth -= contentWidth
            }
        }

        return rows
    }
}

#Preview {
    struct Content: Identifiable, Hashable {
        let id: UUID
        let number: Int
        let red = CGFloat.random(in: 0...1)
        let green = CGFloat.random(in: 0...1)
        let blue = CGFloat.random(in: 0...1)
        let width: CGFloat = CGFloat(Int.random(in: 50...150))
    }

    struct ContentView: View {
        let content: Content

        var body: some View {
            Color(red: content.red, green: content.green, blue: content.blue)
                .opacity(0.6)
                .frame(width: content.width, height: 35)
#if os(iOS)
                .contentShape(.contextMenuPreview, Capsule())
#endif
                .clipShape(Capsule())
                .overlay {
                    Text("\(content.number)")
                }
        }
    }

    struct PreviewView: View {
        @State var items: [Content] = (0...100).map({ Content(id: UUID(), number: $0) })
        @Namespace var animation

        var body: some View {
            VStack {
                ScrollView {
                    HMasonryGrid(items) { data in
                        data.width
                    } content: { data in
                        ContentView(content: data)
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation {
                                        items.removeAll(where: { $0.id == data.id })
                                    }
                                } label: {
                                    Text("Remove")
                                }
                            }
                            .onTapGesture {
                                print(#"Tapped "\#(data.number)"."#)
                            }
                            .matchedGeometryEffect(id: data.id, in: animation)
                    }
                    .padding()
                }

                HStack(spacing: 8) {
                    Button {
                        withAnimation {
                            items.insert(.init(id: UUID(), number: 999), at: 0)
                        }
                    } label: {
                        Text("Add")
                    }
                }
                .padding()
            }
        }
    }

    return PreviewView()
}
