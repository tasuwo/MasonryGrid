//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Foundation

final class HMasonryGridCoordinator<Data: Identifiable & Hashable>: ObservableObject {
    private enum UpdateMode {
        case delay
        // アニメーションを反映させたい場合は、即時の変更が必要
        case immediatedly
    }

    private struct Request {
        var data: [Data]
        var lineSpacing: CGFloat
        var contentSpacing: CGFloat
        var frameWidth: CGFloat
        var width: (Data) -> CGFloat

        func updateMode(for newRequest: Request, with frameTrackingMode: FrameTrackingMode) -> UpdateMode? {
            if data != newRequest.data {
                return .immediatedly
            } else if lineSpacing != newRequest.lineSpacing || contentSpacing != newRequest.contentSpacing {
                return .delay
            } else if frameWidth != newRequest.frameWidth {
                return switch frameTrackingMode {
                case .immediate: .immediatedly
                case .backgroundCalculation: .delay
                case .debounce: nil
                }
            } else {
                return nil
            }
        }
    }

    private var lastRequest: Request?
    private var lastCalculatedRows: [HMasonryGridRow<Data>]?
    private var calculatedWidthByData: [Data: CGFloat] = [:]
    private var calcurationTask: Task<Void, Never>?
    private var frameObserver: LazyFrameObserver?
    private var frameTrackingMode: FrameTrackingMode = .default

    deinit {
        calcurationTask?.cancel()
    }

    @MainActor
    func onRender(data: [Data],
                  width: @escaping (Data) -> CGFloat,
                  lineSpacing: CGFloat,
                  contentSpacing: CGFloat,
                  frameWidth: CGFloat) -> [HMasonryGridRow<Data>]
    {
        guard !data.isEmpty, frameWidth != .zero else {
            return []
        }

        let request = Request(data: data,
                              lineSpacing: lineSpacing,
                              contentSpacing: contentSpacing,
                              frameWidth: frameWidth,
                              width: width)

        defer {
            self.lastRequest = request
        }

        guard let lastCalculatedRows, let lastRequest else {
            return try! calcRowsSync(request)
        }

        switch lastRequest.updateMode(for: request, with: frameTrackingMode) {
        case .delay:
            runRowsCalculation(request)
            return lastCalculatedRows

        case .immediatedly:
            return try! calcRowsSync(request)

        case .none:
            return lastCalculatedRows
        }
    }

    @MainActor
    func onChangeFrame(_ frame: CGSize) {
        frameObserver?.notify(frame)
    }

    @MainActor
    func setFrameTrackingMode(_ mode: FrameTrackingMode) {
        self.frameTrackingMode = mode

        switch mode {
        case .immediate, .backgroundCalculation:
            frameObserver = nil

        case let .debounce(time):
            frameObserver = LazyFrameObserver(.debounce(time))
            frameObserver?.onReceive = { [weak self] _ in
                guard let request = self?.lastRequest else { return }
                self?.runRowsCalculation(request)
            }
        }
    }

    private func runRowsCalculation(_ request: Request) {
        calcurationTask?.cancel()
        calcurationTask = Task { @MainActor [weak self] in
            do {
                try await self?.calcRows(request)
                self?.objectWillChange.send()
            } catch {
                return
            }
        }
    }

    @discardableResult
    private func calcRows(_ request: Request) async throws -> [HMasonryGridRow<Data>] {
        try calcRowsSync(request)
    }

    private func calcRowsSync(_ request: Request) throws -> [HMasonryGridRow<Data>] {
        var rows: [HMasonryGridRow<Data>] = []
        var currentRow = 0

        for d in request.data {
            let contentWidth: CGFloat
            if let width = calculatedWidthByData[d] {
                contentWidth = width
            } else {
                let calculated = request.width(d)
                calculatedWidthByData[d] = calculated
                contentWidth = min(calculated, request.frameWidth)
            }

            if !rows.indices.contains(currentRow) {
                rows.append(.init())
            }

            if rows[currentRow].items.isEmpty {
                rows[currentRow].items.append(.init(width: contentWidth, data: d))
                rows[currentRow].width += contentWidth
            } else if rows[currentRow].width + contentWidth + request.contentSpacing <= request.frameWidth {
                rows[currentRow].items.append(.init(width: contentWidth, data: d))
                rows[currentRow].width += contentWidth + request.contentSpacing
            } else {
                currentRow += 1
                rows.append(.init())
                rows[currentRow].items.append(.init(width: contentWidth, data: d))
                rows[currentRow].width = contentWidth
            }

            try Task.checkCancellation()
        }

        lastCalculatedRows = rows

        return rows
    }

    @MainActor
    func clearWidthCalculationCache() {
        objectWillChange.send()
        calculatedWidthByData = [:]
    }
}
