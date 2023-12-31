//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import AsyncAlgorithms
import Foundation

final class LazyFrameObserver {
    enum Mode {
        case debounce(TimeInterval)
    }

    var onReceive: ((CGSize) -> Void)?

    private let values: AsyncStream<CGSize>
    private let continuation: AsyncStream<CGSize>.Continuation
    private var task: Task<Void, Never>?

    init(_ mode: Mode) {
        let (stream, continuation) = AsyncStream.makeStream(of: CGSize.self)
        self.values = stream
        self.continuation = continuation

        switch mode {
        case let .debounce(time):
            self.task = Task { [weak self, stream] in
                for await value in stream.debounce(for: .seconds(time)) {
                    self?.onReceive?(value)
                }
            }
        }
    }

    deinit {
        task?.cancel()
    }

    func notify(_ frame: CGSize) {
        continuation.yield(frame)
    }
}
