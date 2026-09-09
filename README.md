# FilterablePicker

`FilterablePicker` is a macOS SwiftUI picker backed by `NSPopUpButton` and `NSMenu`. It looks and behaves like a normal menu picker, with AppKit's native filter field for substring searching.

Filtering is localized and case-insensitive. Opening the menu starts with the full list. Typing filters the choices without changing the binding; choosing a menu item commits its ID.

If the required private API is unavailable the component falls back to a `Picker`. `FilterablePickerRuntime.supportsNativeFiltering` can be used to check.

> [!WARNING]
> Filtering uses private AppKit API. Do not use this package in a Mac App Store app. Private API can change or disappear in any macOS update.

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
