//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

public struct VMasonryGrid<Data, Content>: View where Data: Identifiable & Hashable, Content: View {
    struct Column {
        var height: CGFloat = 0
        var data: [Data] = []
    }

    @State private var heights: [Data: CGFloat] = [:]

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private let data: [Data]
    private let numberOfColumns: Int
    private let height: (Data) -> CGFloat
    private let content: (Data) -> Content
    private let columnSpacing: CGFloat
    private let contentSpacing: CGFloat

    public init(_ data: [Data],
                numberOfColumns: Int,
                columnSpacing: CGFloat = 8,
                contentSpacing: CGFloat = 8,
                @ViewBuilder content: @escaping (Data) -> Content,
                height: @escaping (Data) -> CGFloat) {
        self.data = data
        self.numberOfColumns = numberOfColumns
        self.columnSpacing = columnSpacing
        self.contentSpacing = contentSpacing
        self.height = height
        self.content = content
    }

    public var body: some View {
        let columns = calcColumns()
        HStack(alignment: .top, spacing: columnSpacing) {
            ForEach(columns, id: \.data) { column in
                LazyVStack(spacing: contentSpacing) {
                    ForEach(column.data) { item in
                        content(item)
                    }
                }
            }
        }
        .onChange(of: dynamicTypeSize) { _ in
            heights = [:]
        }
    }
}

extension VMasonryGrid {
    private func calcColumns() -> [Column] {
        var columns: [Column] = [Column].init(repeating: .init(), count: numberOfColumns)

        for (i, d) in data.enumerated() {
            let contentHeight: CGFloat = heights[d] ?? height(d)

            let column = columns.map(\.height).enumerated()
                .min(by: { $0.element < $1.element })?
                .offset ?? i % numberOfColumns

            columns[column].height += columns[column].data.isEmpty ? contentHeight : contentHeight + contentSpacing
            columns[column].data.append(d)
        }

        return columns
    }
}

#Preview {
    struct Content: Identifiable, Hashable {
        let id: UUID
        let number: Int
        let red = CGFloat.random(in: 0...1)
        let green = CGFloat.random(in: 0...1)
        let blue = CGFloat.random(in: 0...1)
        let height: CGFloat = CGFloat(Int.random(in: 50...300))
    }

    struct ContentView: View {
        let content: Content

        var body: some View {
            Color(red: content.red, green: content.green, blue: content.blue)
                .opacity(0.6)
                .frame(height: content.height)
#if os(iOS)
                .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 8, style: .continuous))
#endif
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                    VMasonryGrid(items, numberOfColumns: 3) { data in
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
                    } height: { data in
                        data.height
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
