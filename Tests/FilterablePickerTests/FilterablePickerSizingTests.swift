import AppKit
import Testing

@testable import FilterablePicker

@MainActor
struct FilterablePickerSizingTests {
    @Test("Picker width is controlled by its SwiftUI container")
    func widthIsFlexible() {
        let button = FlexiblePopUpButton(frame: .zero, pullsDown: false)
        button.addItems(withTitles: ["Short", String(repeating: "Long title ", count: 20)])

        #expect(button.intrinsicContentSize.width == NSView.noIntrinsicMetric)
        #expect(button.intrinsicContentSize.height > 0)
    }
}
