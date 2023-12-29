//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

public struct HMasonryGrid<Data, Content>: View where Data: Identifiable & Hashable, Content: View {
    struct Row {
        var width: CGFloat = 0
        var data: [Data] = []
    }

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
            ForEach(rows, id: \.data) { row in
                HStack(spacing: contentSpacing) {
                    ForEach(row.data) { item in
                        content(item)
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
    private func calcRows() -> [Row] {
        var rows: [Row] = []
        var currentRow = 0

        for d in data {
            let contentWidth: CGFloat = widths[d] ?? min(width(d), availableWidth)

            if !rows.indices.contains(currentRow) {
                rows.append(.init())
            }

            if rows[currentRow].data.isEmpty {
                rows[currentRow].data.append(d)
                rows[currentRow].width += contentWidth
            } else if rows[currentRow].width + contentWidth + contentSpacing <= availableWidth {
                rows[currentRow].data.append(d)
                rows[currentRow].width += contentWidth + contentSpacing
            } else {
                currentRow += 1
                rows.append(.init())
                rows[currentRow].data.append(d)
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
