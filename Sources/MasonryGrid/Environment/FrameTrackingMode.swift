//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Foundation
import SwiftUI

public enum FrameTrackingMode: Equatable {
    public static let `default` = FrameTrackingMode.backgroundCalculation

    case immediate
    case backgroundCalculation
    case debounce(TimeInterval)
}

private struct FrameTrackingModeKey: EnvironmentKey {
    static let defaultValue: FrameTrackingMode = .default
}

public extension EnvironmentValues {
    var frameTrackingMode: FrameTrackingMode {
        get { self[FrameTrackingModeKey.self] }
        set { self[FrameTrackingModeKey.self] = newValue }
    }
}
