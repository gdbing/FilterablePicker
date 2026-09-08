import AppKit
import FilterablePickerAppKit
import SwiftUI

/// A SwiftUI menu picker that uses AppKit's native menu-filtering interface.
///
/// The filtering interface relies on private AppKit API and is unsuitable for
/// Mac App Store distribution. On systems without that API, this remains a
/// normal, unfiltered `NSPopUpButton`.
@MainActor
public struct FilterablePicker<Item: Identifiable>: NSViewRepresentable {
    private let label: String
    private let items: [Item]
    private let title: (Item) -> String
    @Binding private var selection: Item.ID

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled

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

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.menu = FPCreateNativeFilteringMenu(label) ?? NSMenu(title: label)
        context.coordinator.button = button
        return button
    }

    public func updateNSView(_ button: NSPopUpButton, context: Context) {
        let options = items.map {
            Option(id: AnyHashable($0.id), title: title($0))
        }

        context.coordinator.update(
            options: options,
            selection: AnyHashable(selection),
            label: label,
            onSelect: { selectedID in
                guard let item = items.first(where: { AnyHashable($0.id) == selectedID }) else {
                    return
                }
                selection = item.id
            }
        )

        button.isEnabled = isEnabled && !items.isEmpty
        button.controlSize = controlSize.nsControlSize
        button.font = .systemFont(ofSize: NSFont.systemFontSize(for: button.controlSize))
    }

    @MainActor
    public final class Coordinator: NSObject {
        fileprivate weak var button: NSPopUpButton?

        private var renderedOptions: [Option] = []
        private var menuItems: [NSMenuItem] = []
        private var onSelect: ((AnyHashable) -> Void)?

        fileprivate func update(
            options: [Option],
            selection: AnyHashable,
            label: String,
            onSelect: @escaping (AnyHashable) -> Void
        ) {
            guard let button, let menu = button.menu else { return }

            self.onSelect = onSelect
            if options != renderedOptions {
                renderedOptions = options
                menu.removeAllItems()
                menuItems = options.map { option in
                    let item = NSMenuItem(
                        title: option.title,
                        action: #selector(choose(_:)),
                        keyEquivalent: ""
                    )
                    item.target = self
                    item.representedObject = OptionBox(option)
                    menu.addItem(item)
                    return item
                }
            }

            var selectedItem: NSMenuItem?
            for item in menuItems {
                let isSelected = (item.representedObject as? OptionBox)?.option.id == selection
                item.state = isSelected ? .on : .off
                if isSelected { selectedItem = item }
            }

            if let selectedItem {
                button.select(selectedItem)
                button.synchronizeTitleAndSelectedItem()
            } else {
                button.select(nil)
                button.title = label
            }

            button.setAccessibilityLabel(label)
            button.setAccessibilityValue(selectedItem?.title ?? label)
            button.setAccessibilityHelp("Open the choices and type to filter.")
        }

        @objc private func choose(_ sender: NSMenuItem) {
            guard let option = (sender.representedObject as? OptionBox)?.option else {
                return
            }
            for item in menuItems {
                item.state = item === sender ? .on : .off
            }
            button?.select(sender)
            button?.synchronizeTitleAndSelectedItem()
            onSelect?(option.id)
        }
    }
}

/// Runtime information for apps that want to report or gate filtering support.
public enum FilterablePickerRuntime {
    public static var supportsNativeFiltering: Bool {
        FPIsNativeMenuFilteringAvailable()
    }
}

private struct Option: Equatable {
    let id: AnyHashable
    let title: String
}

private final class OptionBox: NSObject {
    let option: Option

    init(_ option: Option) {
        self.option = option
    }
}

private extension ControlSize {
    var nsControlSize: NSControl.ControlSize {
        switch self {
        case .mini: .mini
        case .small: .small
        case .large: .large
        default: .regular
        }
    }
}
