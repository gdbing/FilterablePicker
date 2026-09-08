# FilterablePicker

A small macOS-only SwiftUI picker with a native AppKit popup button and a menu-style, type-to-filter popup. Requires macOS 14 and Swift 6. No dependencies.

```swift
import SwiftUI
import FilterablePicker

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

Add this folder as a local package dependency in Xcode, or use `.package(path: "../FilterablePicker")` in another package. Add the `FilterablePicker` library product to your app target.

## Interaction

- Click and release the button to keep all choices open. The committed selection has a checkmark. Dragging from the opening press into the menu can also select on release.
- Type to filter by a localized, case- and diacritic-insensitive substring. The query appears in a small secondary-text row while filtering.
- Delete removes the preceding composed character. Option-Delete removes the preceding word. Command-Delete removes everything back to the beginning of the filter.
- Command-V pastes plain text; line breaks become spaces.
- Up/Down changes the highlighted choice; Return commits it. Hover and click also work, including opening the button and dragging into the choices.
- Escape, clicking outside, switching apps, or dismissing the parent window cancels. Tab/Shift-Tab cancels and moves focus to the next/previous control.
- Left/Right and other cursor or selection movement commands do nothing outside input-method composition. No caret is drawn, and clicks cannot reposition it. Copy, Cut, Select All and Undo shortcuts are intentionally inactive in the transient filter.
- No matches leaves only the query in secondary text, with no selection highlight or selectable placeholder. Return cannot commit an unsuccessful filter. Deleting characters restores matches.
- Each opening begins with an empty filter. Filtering and hovering never mutate your selection binding.

Items must have unique, stable IDs. Duplicate display titles are supported. Supply already-localized titles and an accessible control label. An externally changed item list or selection updates an open popup; removing the highlighted item chooses a remaining match. An empty item list displays “No choices.” The view respects `.disabled` and `.controlSize`.

## Design

The closed control is an `NSPopUpButton`. The popup is a borderless child `NSPanel`, using the system menu visual-effect material, system menu font, checkmarks, a scrollable AppKit table, and rounded rows. Selected rows use an emphasized `NSVisualEffectView` with `.selection` material (Apple's replacement for the deprecated `NSColor.selectedMenuItemColor`). The outer corner radius is 10 points and the selection radius is 6 points. It is a custom menu-style surface, not a private or modified `NSMenu`; it does not promise pixel-identical rendering across macOS releases.

Text goes through a real, attached `NSTextView`, including AppKit key bindings, replacement ranges and marked-text composition. It does not reconstruct strings from raw key codes. While an input method is composing text, that input method retains its native cursor/selection behavior; Return must finish composition before it can choose an item. The ordinary filter remains append-only.

Accessibility includes a labeled popup button, a native text input and table, choice actions, selection state and result-count announcements. Full VoiceOver and third-party input-method certification should be part of testing in the consuming app.

## Try it

Open `Package.swift` in Xcode, choose the **FilterablePickerDemo** scheme and **My Mac**, and run. The executable target is the demo project; no separate `.xcodeproj` is needed. Its complete UI is in `Sources/FilterablePickerDemo/Demo.swift`.

For a normal app bundle launched from Terminal:

```sh
./Scripts/run-demo.sh
```

This builds and locally signs `.build/FilterablePickerDemo.app`, then opens it. No signing identity is required. Quit the demo before rebuilding it.

Or run the executable and tests directly:

```sh
swift run FilterablePickerDemo
swift test
```

The demo places the filterable control beside a standard SwiftUI Picker for comparison. It includes substring matches, accented text, Japanese and emoji.

With the Swift 6.4 Command Line Tools, use `./Scripts/test.sh` if `swift test` cannot locate `TestingMacros` or the Testing runtime. The script supplies the paths to the toolchain's existing libraries for that invocation; it installs nothing and changes no system configuration.

Validated locally on macOS 27 with Swift 6.4: all 15 tests pass using that script's compiler/linker options. Live demo checks verified `aft` filtering, Delete to `af`, Command-Delete clearing, ignored Left movement, Down/Return selection, and a nonselectable no-matches state. Earlier deployment targets are declared but have not been run on this machine.

## Verification checklist

Automated tests cover matching, provisional selection, empty results, duplicate titles, navigation bounds, native character/word/line deletion, composed emoji, ignored cursor movement, marked-text replacement and single-line insertion.

For integration testing, also check:

- Light and dark appearance, Increase Contrast and Reduce Transparency.
- Long lists, long labels, scrolling and screen edges, including multiple displays.
- Keyboard opening, hover, click, click-and-drag, cancellation and focus restoration.
- Japanese/Chinese/Korean input methods, dead keys, dictation and custom key bindings.
- VoiceOver opening, exploring and choosing results.

The package uses public AppKit and SwiftUI APIs only.
