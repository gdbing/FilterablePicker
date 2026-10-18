# FilterablePicker

`FilterablePicker` is a macOS SwiftUI picker backed by `NSPopUpButton` and `NSMenu`. It looks and behaves like a normal menu picker, with AppKit's native filter field for substring searching.

Filtering is localized and case-insensitive. Opening the menu starts with the full list. Typing filters the choices without changing the binding; choosing a menu item commits its ID.

The picker takes the horizontal space offered by its SwiftUI layout instead of widening its container to fit the longest item. A selected title that does not fit is truncated; menu items retain their full titles.

If the required private API is unavailable the component falls back to a `Picker`. `FilterablePickerRuntime.supportsNativeFiltering` can be used to check.

> [!WARNING]
> Filtering uses private AppKit API. Do not use this package in a Mac App Store app. Private API can change or disappear in any macOS update.

## Installation

In Xcode, choose **File > Add Package Dependencies** and enter:

```text
https://github.com/gdbing/FilterablePicker.git
```

Select the `FilterablePicker` library product and add it to your macOS app target.
The package supports macOS 14 and later.

For a Swift Package, add it to `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/gdbing/FilterablePicker.git",
        from: "1.0.0"
    )
]
```

## Usage

```swift
import FilterablePicker
import SwiftUI

struct TimeOfDay: Identifiable {
    let id: String
    let name: String
}

struct Example: View {
    @State private var selectedID = "morning"

    private let times = [
        TimeOfDay(id: "morning", name: "Morning"),
        TimeOfDay(id: "afternoon", name: "Afternoon"),
        TimeOfDay(id: "late-afternoon", name: "Late afternoon")
    ]

    var body: some View {
        FilterablePicker(
            "Time of day",
            selection: $selectedID,
            items: times,
            title: \.name
        )
        .frame(width: 200)
    }
}
```

Add the package to your app and link the `FilterablePicker` library product. Items need unique, stable IDs; display titles may be duplicated.

### Sections

Pass `section:` to group items under native menu section headers. Consecutive items with the same section share one header; an item whose section is `nil` has none.

```swift
FilterablePicker(
    "Model",
    selection: $selectedID,
    items: models,
    title: \.name,
    section: \.group
)
```

Typing a section's title shows every item in that section. Otherwise items match on their own titles, and a header is hidden while none of its items match.
