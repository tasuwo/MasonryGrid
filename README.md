MasonryGrid
===========

A masonry grid layout view for SwiftUI.

|Horizontal|Vertical|
|----------|--------|
|<img src="./Screenshots/HMasonryGrid.png" width="200px" height="auto" />|<img src="./Screenshots/VMasonryGrid.png" width="200px" height="auto" />|

## Features

- [x] Vertical scroll.
- [x] Spacing curtomizable.
- [x] Lazy loading.
- [x] Items update can be animated.

## Requirements

- iOS 15.0+ / macOS 12.0+
- Xcode 15.0+
- Swift 5.9+

## Usage

### Basic

It takes an array of data and calculates the optimal arrangement of the data items into rows/columns. The recommended width/height for each item in the grid is required for lazy loading.

```swift
HMasonryGrid(items) { item in
    ItemView(item)
} width: { item in
    item.width
}
```

`VMasonryGrid` requires `numberOfColumns` additionaly.

```swift
VMasonryGrid(items, numberOfColumns: 3) { item in
    ItemView(item)
} height: { item in
    item.height
}
```

### Animation

Use [matchedGeometryEffect](https://developer.apple.com/documentation/swiftui/view/matchedgeometryeffect(id:in:properties:anchor:issource:)) if you want to animate items when they are updated.

```swift
@Namespace var animation

VMasonryGrid(items, numberOfColumns: 3) { item in
    ItemView(item)
        .matchedGeometryEffect(id: item.id, in: animation)
} height: { item in
    item.height
}
```

## License

The MasonryGrid is released under the MIT License. See the [LICENSE](LICENSE.md) file for more information.
