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
    private let section: (Item) -> String?
    @Binding private var selection: Item.ID

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ label: String,
        selection: Binding<Item.ID>,
        items: [Item],
        title: @escaping (Item) -> String
    ) {
        self.init(label, selection: selection, items: items, title: title, section: { _ in nil })
    }

    /// A picker whose items are grouped under section headers.
    ///
    /// Consecutive items with the same section share one header above them; an
    /// item whose section is `nil` has none. Typing a section's title shows every
    /// item in it, and a header is hidden while none of its items match.
    public init(
        _ label: String,
        selection: Binding<Item.ID>,
        items: [Item],
        title: @escaping (Item) -> String,
        section: @escaping (Item) -> String?
    ) {
        self.label = label
        self.items = items
        self.title = title
        self.section = section
        _selection = selection
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeNSView(context: Context) -> NSPopUpButton {
        let button = FlexiblePopUpButton(frame: .zero, pullsDown: false)
        button.menu = FPCreateNativeFilteringMenu(label) ?? NSMenu(title: label)
        button.cell?.lineBreakMode = .byTruncatingTail
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        context.coordinator.button = button
        return button
    }

    public func updateNSView(_ button: NSPopUpButton, context: Context) {
        let options = items.map {
            Option(id: AnyHashable($0.id), title: title($0), section: section($0))
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
                var currentSection: String?
                menuItems = options.map { option in
                    if let section = option.section, section != currentSection {
                        menu.addItem(.sectionHeader(title: section))
                    }
                    currentSection = option.section
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

/// Menu item titles determine an `NSPopUpButton`'s normal intrinsic width. The
/// menu should be able to fit those titles, but the control should take the
/// width offered by SwiftUI rather than widening its container to match them.
final class FlexiblePopUpButton: NSPopUpButton {
    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: super.intrinsicContentSize.height)
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
    let section: String?
}

private final class OptionBox: NSObject {
    let option: Option

    init(_ option: Option) {
        self.option = option
    }
}

extension ControlSize {
    fileprivate var nsControlSize: NSControl.ControlSize {
        switch self {
        case .mini: .mini
        case .small: .small
        case .large: .large
        default: .regular
        }
    }
}
