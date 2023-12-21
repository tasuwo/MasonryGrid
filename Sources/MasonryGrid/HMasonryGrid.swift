//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

public struct HMasonryGrid<Data, Content>: View where Data: Identifiable & Hashable, Content: View {
    @State private var availableWidth: CGFloat = 0
    @State private var contentWidths: [Data: CGFloat] = [:]

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var data: [Data]
    private let width: (Data) -> CGFloat
    private let content: (Data) -> Content
    private let lineSpacing: CGFloat
    private let contentSpacing: CGFloat

    public init(_ data: [Data],
                lineSpacing: CGFloat = 10,
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
                            .fixedSize()
                    }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .background(
            Color.clear
                .frame(height: 0)
                .onChangeFrame { frame in
                    contentWidths = [:]
                    availableWidth = frame.width
                }
        )
        .onChange(of: dynamicTypeSize) { _ in
            contentWidths = [:]
        }
    }
}

extension HMasonryGrid {
    private func calcRows() -> [[Data]] {
        var rows: [[Data]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth

        for d in data {
            let contentWidth: CGFloat = contentWidths[d] ?? min(width(d), availableWidth)
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
        let name: String
    }

    struct ContentView: View {
        let tag: Content
        let padding: CGFloat = 8

        var body: some View {
            Text(tag.name)
                .lineLimit(1)
                .font(.body)
                .padding([.leading, .trailing], padding * 3 / 2)
                .padding([.top, .bottom], padding)
                .overlay(
                    Capsule()
                        .stroke(lineWidth: 0.5)
                        .foregroundColor(.gray)
                )
#if os(iOS)
                .contentShape(.contextMenuPreview, Capsule())
#endif
                .clipShape(Capsule())
        }

        static func preferredWidth(name: String, padding: CGFloat) -> CGFloat {
            return name.labelSize(with: .body).width + (padding * 3 / 2) * 2
        }
    }

    struct PreviewView: View {
        @State var tags: [Content] = [
            Content(id: UUID(), name: "This"),
            Content(id: UUID(), name: "is"),
            Content(id: UUID(), name: "Masonry"),
            Content(id: UUID(), name: "Grid."),
            Content(id: UUID(), name: "This"),
            Content(id: UUID(), name: "Grid"),
            Content(id: UUID(), name: "allows"),
            Content(id: UUID(), name: "displaying"),
            Content(id: UUID(), name: "very"),
            Content(id: UUID(), name: "long"),
            Content(id: UUID(), name: "text"),
            Content(id: UUID(), name: "like"),
            Content(id: UUID(), name: "Too Too Too Too Long Text"),
            Content(id: UUID(), name: "or"),
            Content(id: UUID(), name: "Toooooooooooooooooooooooooooooo Looooooooooooooooooooooooooooooooooooooong Text."),
            Content(id: UUID(), name: "All"),
            Content(id: UUID(), name: "content"),
            Content(id: UUID(), name: "sizes"),
            Content(id: UUID(), name: "are"),
            Content(id: UUID(), name: "flexible"),
        ]
        @State var tagName: String = ""
        @Namespace var animation

        var body: some View {
            VStack {
                ScrollView {
                    HMasonryGrid(tags) { tag in
                        ContentView.preferredWidth(name: tag.name, padding: 8)
                    } content: { tag in
                        ContentView(tag: tag)
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation {
                                        tags.removeAll(where: { $0.id == tag.id })
                                    }
                                } label: {
                                    Text("Remove")
                                }
                            }
                            .onTapGesture {
                                print(#"Tapped "\#(tag.name)"."#)
                            }
                            .matchedGeometryEffect(id: tag.id, in: animation)
                    }
                    .padding()
                }

                HStack(spacing: 8) {
                    TextField("Name", text: $tagName)
                    Button {
                        withAnimation {
                            tags.insert(.init(id: UUID(), name: tagName), at: 0)
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

#if DEBUG && os(iOS)

import UIKit

extension String {
    func labelSize(with font: Font) -> CGSize {
        let label = UILabel()
        label.font = font.uiFont
        label.adjustsFontForContentSizeCategory = true
        label.text = self
        label.sizeToFit()
        return label.frame.size
    }
}

extension Font {
    var uiFont: UIFont {
        switch self {
        case .largeTitle: UIFont.preferredFont(forTextStyle: .largeTitle)
        case .title: UIFont.preferredFont(forTextStyle: .title1)
        case .title2: UIFont.preferredFont(forTextStyle: .title2)
        case .title3: UIFont.preferredFont(forTextStyle: .title3)
        case .headline: UIFont.preferredFont(forTextStyle: .headline)
        case .subheadline: UIFont.preferredFont(forTextStyle: .subheadline)
        case .callout: UIFont.preferredFont(forTextStyle: .callout)
        case .caption: UIFont.preferredFont(forTextStyle: .caption1)
        case .caption2: UIFont.preferredFont(forTextStyle: .caption2)
        case .footnote: UIFont.preferredFont(forTextStyle: .footnote)
        case .body: UIFont.preferredFont(forTextStyle: .body)
        default: UIFont.preferredFont(forTextStyle: .body)
        }
    }
}

#endif

#if DEBUG && os(macOS)

import AppKit

extension String {
    func labelSize(with font: Font) -> CGSize {
        let label = NSTextField(labelWithString: self)
        label.font = font.nsFont
        label.sizeToFit()
        return label.frame.size
    }
}

extension Font {
    var nsFont: NSFont {
        switch self {
        case .largeTitle: NSFont.preferredFont(forTextStyle: .largeTitle)
        case .title: NSFont.preferredFont(forTextStyle: .title1)
        case .title2: NSFont.preferredFont(forTextStyle: .title2)
        case .title3: NSFont.preferredFont(forTextStyle: .title3)
        case .headline: NSFont.preferredFont(forTextStyle: .headline)
        case .subheadline: NSFont.preferredFont(forTextStyle: .subheadline)
        case .callout: NSFont.preferredFont(forTextStyle: .callout)
        case .caption: NSFont.preferredFont(forTextStyle: .caption1)
        case .caption2: NSFont.preferredFont(forTextStyle: .caption2)
        case .footnote: NSFont.preferredFont(forTextStyle: .footnote)
        case .body: NSFont.preferredFont(forTextStyle: .body)
        default: NSFont.preferredFont(forTextStyle: .body)
        }
    }
}

#endif
