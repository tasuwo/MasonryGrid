//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Foundation

struct HMasonryGridRow<Data: Identifiable & Hashable> {
    struct Item: Identifiable, Hashable {
        var id: Data.ID { data.id }
        var width: CGFloat
        var data: Data
    }

    var width: CGFloat = 0
    var items: [Item] = []
}
