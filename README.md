# FilterablePicker

`FilterablePicker` is a macOS SwiftUI picker backed by a native `NSPopUpButton` and `NSMenu`. It looks and behaves like a normal menu picker, while AppKit adds its native filter field for substring searching.

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

## Behavior

The closed control, menu window, filter field, keyboard navigation, scrolling, highlighting, selection, dismissal, accessibility, and visual materials are all AppKit components. This package only builds the menu items and handles substring matching when AppKit supplies a search query.

Filtering is localized and case-insensitive. Opening the menu starts with the full list. Typing filters the choices without changing the binding; choosing a menu item commits its ID.

If the private filtering capability is unavailable, the component falls back to an ordinary unfiltered menu picker. Apps can inspect `FilterablePickerRuntime.supportsNativeFiltering` when they need to distinguish these cases.

## Compatibility and distribution

The native filtering behavior has been validated on macOS 27. Earlier macOS versions have not been validated and may use the unfiltered fallback. Because the interface is private, compatibility must be checked on each macOS release your app supports.

The package links only system AppKit and SwiftUI frameworks. It does not load DVTKit or require Xcode on the user's Mac.

Apple's App Review Guidelines require App Store apps to use public APIs, so this component is intended for direct distribution. Apple's notarization service is separate from App Review and primarily checks malicious content and code-signing correctness; the containing app should still be Developer ID signed, hardened-runtime enabled, and notarized.

## Implementation

Most of the behavior is in AppKit. The private bridge is contained in `Sources/FilterablePickerAppKit/AppKitFilteringMenu.m`; the SwiftUI wrapper is in `Sources/FilterablePicker/FilterablePicker.swift`.

Build the package with:

```sh
swift build
```
