//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

public struct HMasonryGrid<Data, Content>: View where Data: Identifiable & Hashable, Content: View {
    struct Row {
        struct Item: Identifiable, Hashable {
            var id: Data.ID { data.id }
            var width: CGFloat
            var data: Data
        }

        var width: CGFloat = 0
        var items: [Item] = []
    }

    class Cache: ObservableObject {
        var widths: [Data: CGFloat] = [:]
    }

    @State private var availableWidth: CGFloat = 0
    @StateObject private var cache: Cache = .init()

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var data: [Data]
    private let width: (Data) -> CGFloat
    private let content: (Data) -> Content
    private let lineSpacing: CGFloat
    private let contentSpacing: CGFloat

    public init(_ data: [Data],
                lineSpacing: CGFloat = 8,
                contentSpacing: CGFloat = 8,
                @ViewBuilder content: @escaping (Data) -> Content,
                width: @escaping (Data) -> CGFloat) {
        self.data = data
        self.lineSpacing = lineSpacing
        self.contentSpacing = contentSpacing
        self.width = width
        self.content = content
    }

    public var body: some View {
        let rows = calcRows()
        LazyVStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(rows, id: \.items) { row in
                HStack(spacing: contentSpacing) {
                    ForEach(row.items) { item in
                        content(item.data)
                            .frame(width: item.width)
                            .frame(maxWidth: availableWidth)
                    }
                }
                .frame(width: row.width)
            }
        }
        .background(
            Color.clear
                .frame(height: 0)
                .onChangeFrame { frame in
                    availableWidth = frame.width
                }
        )
        .onChange(of: dynamicTypeSize) { _ in
            cache.widths = [:]
        }
    }
}

extension HMasonryGrid {
    private func calcRows() -> [Row] {
        var rows: [Row] = []
        var currentRow = 0

        for d in data {
            let contentWidth: CGFloat
            if let width = cache.widths[d] {
                contentWidth = width
            } else {
                let calculated = width(d)
                cache.widths[d] = calculated
                contentWidth = min(calculated, availableWidth)
            }

            if !rows.indices.contains(currentRow) {
                rows.append(.init())
            }

            if rows[currentRow].items.isEmpty {
                rows[currentRow].items.append(.init(width: contentWidth, data: d))
                rows[currentRow].width += contentWidth
            } else if rows[currentRow].width + contentWidth + contentSpacing <= availableWidth {
                rows[currentRow].items.append(.init(width: contentWidth, data: d))
                rows[currentRow].width += contentWidth + contentSpacing
            } else {
                currentRow += 1
                rows.append(.init())
                rows[currentRow].items.append(.init(width: contentWidth, data: d))
                rows[currentRow].width = contentWidth
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
        @State var items: [Content] = (0...500).map({ Content(id: UUID(), number: $0) })
        @Namespace var animation

        var body: some View {
            VStack {
                ScrollView {
                    HMasonryGrid(items) { data in
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
                    } width: { data in
                        data.width
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
