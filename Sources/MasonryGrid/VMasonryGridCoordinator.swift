//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Foundation

final class VMasonryGridCoordinator<Data: Identifiable & Hashable>: ObservableObject {
    private enum UpdateMode {
        case delay
        // アニメーションを反映させたい場合は、即時の変更が必要
        case immediatedly
    }

    private struct Request {
        var data: [Data]
        var numberOfColumns: Int
        var height: (Data) -> CGFloat
        var columnSpacing: CGFloat
        var contentSpacing: CGFloat

        func updateMode(for newRequest: Request) -> UpdateMode? {
            if data != newRequest.data {
                return .immediatedly
            } else if columnSpacing != newRequest.columnSpacing || contentSpacing != newRequest.contentSpacing || numberOfColumns != newRequest.numberOfColumns {
                return .immediatedly
            } else {
                return nil
            }
        }
    }

    private var lastRequest: Request?
    private var lastCalculatedColumns: [VMasonryGridColumn<Data>]?
    private var calculatedHeightByData: [Data: CGFloat] = [:]
    private var calcurationTask: Task<Void, Never>?

    deinit {
        calcurationTask?.cancel()
    }

    @MainActor
    func onRender(data: [Data],
                  numberOfColumns: Int,
                  height: @escaping (Data) -> CGFloat,
                  columnSpacing: CGFloat,
                  contentSpacing: CGFloat) -> [VMasonryGridColumn<Data>]
    {
        guard !data.isEmpty else {
            return []
        }

        let request = Request(data: data,
                              numberOfColumns: numberOfColumns,
                              height: height,
                              columnSpacing: columnSpacing,
                              contentSpacing: contentSpacing)

        defer {
            self.lastRequest = request
        }

        guard let lastCalculatedColumns, let lastRequest else {
            return try! calcColumnsSync(request)
        }

        switch lastRequest.updateMode(for: request) {
        case .delay:
            runColumnsCalculation(request)
            return lastCalculatedColumns

        case .immediatedly:
            return try! calcColumnsSync(request)

        case .none:
            return lastCalculatedColumns
        }
    }

    private func runColumnsCalculation(_ request: Request) {
        calcurationTask?.cancel()
        calcurationTask = Task { @MainActor [weak self] in
            do {
                try await self?.calcColumns(request)
                self?.objectWillChange.send()
            } catch {
                return
            }
        }
    }

    @discardableResult
    private func calcColumns(_ request: Request) async throws -> [VMasonryGridColumn<Data>] {
        return try calcColumnsSync(request)
    }

    private func calcColumnsSync(_ request: Request) throws -> [VMasonryGridColumn<Data>] {
        var columns = [VMasonryGridColumn<Data>].init(repeating: .init(), count: request.numberOfColumns)

        for (i, d) in request.data.enumerated() {
            let contentHeight: CGFloat
            if let height = calculatedHeightByData[d] {
                contentHeight = height
            } else {
                let calculated = request.height(d)
                calculatedHeightByData[d] = calculated
                contentHeight = calculated
            }

            let column = columns.map(\.height).enumerated()
                .min(by: { $0.element < $1.element })?
                .offset ?? i % request.numberOfColumns

            columns[column].height += columns[column].data.isEmpty ? contentHeight : contentHeight + request.contentSpacing
            columns[column].data.append(d)

            try Task.checkCancellation()
        }

        lastCalculatedColumns = columns

        return columns
    }

    @MainActor
    func clearHeightCalculationCache() {
        objectWillChange.send()
        calculatedHeightByData = [:]
    }
}
