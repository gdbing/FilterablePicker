import AppKit
import SwiftUI

/// A macOS popup picker with native text editing and substring filtering.
///
/// Option IDs must be unique and stable. Filtering never changes `selection`;
/// a click or Return commits the highlighted option.
@MainActor
public struct FilterablePicker<Item: Identifiable>: NSViewRepresentable {
    private let label: String
    private let items: [Item]
    private let title: (Item) -> String
    @Binding private var selection: Item.ID
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.controlSize) private var controlSize

    public init(
        _ label: String,
        selection: Binding<Item.ID>,
        items: [Item],
        title: @escaping (Item) -> String
    ) {
        self.label = label
        self.items = items
        self.title = title
        _selection = selection
    }

    public func makeNSView(context: Context) -> FilterablePickerButton {
        FilterablePickerButton(frame: .zero, pullsDown: false)
    }

    public func updateNSView(_ button: FilterablePickerButton, context: Context) {
        let options = items.map { PickerOption(id: AnyHashable($0.id), title: title($0)) }
        button.configure(options: options, selection: AnyHashable(selection), label: label)
        button.isEnabled = isEnabled
        switch controlSize {
        case .mini: button.controlSize = .mini
        case .small: button.controlSize = .small
        case .large: button.controlSize = .large
        default: button.controlSize = .regular
        }
        button.font = .systemFont(ofSize: NSFont.systemFontSize(for: button.controlSize))
        button.onSelect = { id in
            if let item = items.first(where: { AnyHashable($0.id) == id }) {
                selection = item.id
            }
        }
        if !isEnabled { button.dismissPopup() }
    }

    public static func dismantleNSView(_ button: FilterablePickerButton, coordinator: ()) {
        button.dismissPopup()
    }
}

/// The AppKit backing view. Configure it through `FilterablePicker`.
@MainActor
public final class FilterablePickerButton: NSPopUpButton {
    private var options: [PickerOption] = []
    private var selectedID: AnyHashable?
    private var popup: PickerPopup?
    var onSelect: ((AnyHashable) -> Void)?

    func configure(options: [PickerOption], selection: AnyHashable, label: String) {
        self.options = options
        selectedID = selection
        let displayedTitle = options.first(where: { $0.id == selection })?.title ?? label
        if title != displayedTitle || numberOfItems != 1 {
            removeAllItems()
            addItem(withTitle: displayedTitle)
        }
        setAccessibilityLabel(label)
        setAccessibilityValue(displayedTitle)
        setAccessibilityHelp("Open the choices and type to filter. Use Up and Down to choose, Return to select, or Escape to cancel.")
        popup?.update(options: options, selection: selection)
        invalidateIntrinsicContentSize()
    }

    public override func mouseDown(with event: NSEvent) { showPopup(openingEvent: event) }
    public override func performClick(_ sender: Any?) { showPopup() }
    public override func accessibilityPerformPress() -> Bool {
        guard isEnabled else { return false }
        showPopup()
        return true
    }

    public override func accessibilityPerformShowMenu() -> Bool { accessibilityPerformPress() }

    public override func keyDown(with event: NSEvent) {
        if [36, 49, 125, 126].contains(event.keyCode) { showPopup() }
        else { super.keyDown(with: event) }
    }

    public override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow !== window { dismissPopup() }
        super.viewWillMove(toWindow: newWindow)
    }

    private func showPopup(openingEvent: NSEvent? = nil) {
        guard isEnabled, window != nil else { return }
        if popup != nil { dismissPopup(); return }
        let openingLocation = openingEvent.flatMap { event in
            event.window?.convertPoint(toScreen: event.locationInWindow)
        }
        let popup = PickerPopup(anchor: self, options: options, selection: selectedID, openingLocation: openingLocation)
        self.popup = popup
        popup.onSelect = { [weak self] id in self?.onSelect?(id) }
        popup.onDismiss = { [weak self] in self?.popup = nil }
        popup.present()
    }

    func dismissPopup() { popup?.dismiss() }
}
