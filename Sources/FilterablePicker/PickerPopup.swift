import AppKit

@MainActor
private final class MenuPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
private final class MenuBackground: NSVisualEffectView {
    override var isFlipped: Bool { true }
}

@MainActor
private final class MenuRow: NSTableRowView {
    private let selection = NSVisualEffectView()

    override var isSelected: Bool {
        didSet { selection.isHidden = !isSelected }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        selection.material = .selection
        selection.blendingMode = .withinWindow
        selection.state = .active
        selection.isEmphasized = true
        selection.wantsLayer = true
        selection.layer?.cornerRadius = 6
        selection.layer?.cornerCurve = .continuous
        selection.layer?.masksToBounds = true
        selection.isHidden = !isSelected
        addSubview(selection, positioned: .below, relativeTo: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        selection.frame = bounds.insetBy(dx: 4, dy: 0)
    }

    // The visual-effect view supplies AppKit's menu highlight, including vibrancy.
    override func drawSelection(in dirtyRect: NSRect) {}
}

@MainActor
private final class MenuCell: NSTableCellView {
    var choose: (() -> Void)?
    override func accessibilityPerformPress() -> Bool {
        choose?()
        return choose != nil
    }
}

@MainActor
private final class MenuTable: NSTableView {
    var onHover: ((Int) -> Void)?
    var onChoose: ((Int) -> Void)?
    private var hoverArea: NSTrackingArea?
    override var acceptsFirstResponder: Bool { false }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self)
        addTrackingArea(area)
        hoverArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        onHover?(row(at: convert(event.locationInWindow, from: nil)))
    }

    override func mouseExited(with event: NSEvent) { onHover?(-1) }

    override func mouseDown(with event: NSEvent) {
        onHover?(row(at: convert(event.locationInWindow, from: nil)))
    }

    override func mouseUp(with event: NSEvent) {
        onChoose?(row(at: convert(event.locationInWindow, from: nil)))
    }
}

@MainActor
final class PickerPopup: NSObject, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate {
    var onSelect: ((AnyHashable) -> Void)?
    var onDismiss: (() -> Void)?
    private weak var anchor: NSView?
    private weak var previousResponder: NSResponder?
    private let panel = MenuPanel(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
    private let background = MenuBackground()
    private let scroll = NSScrollView()
    private let table = MenuTable()
    private let editor = FilterEditor()
    private let emptyLabel = NSTextField(labelWithString: "No choices")
    private let divider = NSBox()
    private var state: PickerState
    private var openingClick: OpeningClick
    private var visible: [PickerOption] = []
    private var eventMonitor: Any?
    private var observers: [NSObjectProtocol] = []
    private var isPresented = false
    private var menuWidth: CGFloat = 180
    private var topEdge: CGFloat = 0
    private let rowHeight: CGFloat = 24
    private let padding: CGFloat = 5

    init(anchor: NSView, options: [PickerOption], selection: AnyHashable?, openingLocation: CGPoint? = nil) {
        self.anchor = anchor
        state = PickerState(options: options, selection: selection)
        openingClick = OpeningClick(origin: openingLocation)
        super.init()
        configurePanel()
        configureTable()
        configureEditor()
    }

    private func configurePanel() {
        panel.delegate = self
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.hidesOnDeactivate = true
        panel.acceptsMouseMovedEvents = true
        panel.isMovable = false
        panel.animationBehavior = .none
        panel.setAccessibilityLabel("Filterable choices")
        background.material = .menu
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 10
        background.layer?.cornerCurve = .continuous
        background.layer?.masksToBounds = true
        panel.contentView = background
        divider.boxType = .separator
        background.addSubview(divider)
        emptyLabel.font = .menuFont(ofSize: 0)
        emptyLabel.textColor = .secondaryLabelColor
        background.addSubview(emptyLabel)
    }

    private func configureTable() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("choice"))
        table.addTableColumn(column)
        table.headerView = nil
        table.backgroundColor = .clear
        table.rowHeight = rowHeight
        table.intercellSpacing = .zero
        table.style = .plain
        table.selectionHighlightStyle = .regular
        table.allowsEmptySelection = true
        table.allowsMultipleSelection = false
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        table.dataSource = self
        table.delegate = self
        table.setAccessibilityLabel("Matching choices")
        table.onHover = { [weak self] row in self?.highlight(row) }
        table.onChoose = { [weak self] row in
            guard let self, self.visible.indices.contains(row) else { return }
            self.state.highlight(self.visible[row].id)
            self.commit()
        }
        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay
        background.addSubview(scroll)
    }

    private func configureEditor() {
        editor.delegate = self
        editor.onMove = { [weak self] offset in
            guard let self else { return }
            self.state.move(offset)
            self.updateHighlight(scrollToSelection: true)
        }
        editor.onCommit = { [weak self] in self?.commit() }
        editor.onCancel = { [weak self] in self?.dismiss() }
        editor.onTab = { [weak self] backwards in
            guard let self, let anchor = self.anchor, let window = anchor.window else { return }
            self.dismiss()
            if backwards { window.selectPreviousKeyView(anchor) }
            else { window.selectNextKeyView(anchor) }
        }
        background.addSubview(editor)
    }

    func present() {
        guard let anchor, let parent = anchor.window, !isPresented else { return }
        previousResponder = parent.firstResponder
        let font = NSFont.menuFont(ofSize: 0)
        let titleWidth = state.options.map { ($0.title as NSString).size(withAttributes: [.font: font]).width }.max() ?? 100
        let screen = parent.screen?.visibleFrame ?? NSScreen.main!.visibleFrame
        menuWidth = min(max(anchor.bounds.width + 8, titleWidth + 48, 140), min(420, screen.width - 16))
        let anchorRect = parent.convertToScreen(anchor.convert(anchor.bounds, to: nil))
        let selectedRow = state.matches.firstIndex(where: { $0.id == state.highlightedID }) ?? 0
        topEdge = min(screen.maxY - 4, anchorRect.midY + padding + (CGFloat(min(selectedRow, 10)) + 0.5) * rowHeight)
        let x = min(max(anchorRect.minX - 4, screen.minX + 4), screen.maxX - menuWidth - 4)
        panel.setFrame(NSRect(x: x, y: topEdge - 30, width: menuWidth, height: 30), display: false)
        panel.appearance = anchor.effectiveAppearance
        isPresented = true
        reload()
        parent.addChildWindow(panel, ordered: .above)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(editor)
        installDismissalObservers(parent: parent)
        NSAccessibility.post(element: panel, notification: .created)
    }

    func update(options: [PickerOption], selection: AnyHashable?) {
        guard state.options != options || state.selection != selection else { return }
        state.options = options
        state.selection = selection
        state.reconcileHighlight()
        if isPresented { reload() }
    }

    func dismiss() {
        guard isPresented else { return }
        isPresented = false
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = nil
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
        let parent = panel.parent
        let shouldRestoreFocus = panel.isKeyWindow && NSApp.isActive
        parent?.removeChildWindow(panel)
        panel.orderOut(nil)
        if shouldRestoreFocus {
            parent?.makeKey()
            parent?.makeFirstResponder(previousResponder ?? anchor)
        }
        onDismiss?()
    }

    func windowDidResignKey(_ notification: Notification) { dismiss() }

    private func installDismissalObservers(parent: NSWindow) {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            // AppKit invokes local monitors synchronously on the main thread.
            // Return only the disposition across the isolation check, not NSEvent.
            let forwardEvent = MainActor.assumeIsolated {
                guard let self, self.isPresented else { return true }
                if event.type == .leftMouseDragged || event.type == .leftMouseUp {
                    let screenPoint = event.window?.convertPoint(toScreen: event.locationInWindow) ?? NSEvent.mouseLocation
                    if event.type == .leftMouseDragged {
                        self.openingClick.dragged(to: screenPoint)
                    } else if self.openingClick.shouldIgnoreRelease(at: screenPoint) {
                        return false
                    }
                    let point = self.table.convert(self.panel.convertPoint(fromScreen: screenPoint), from: nil)
                    if self.table.visibleRect.contains(point) {
                        let row = self.table.row(at: point)
                        self.highlight(row)
                        if event.type == .leftMouseUp, self.visible.indices.contains(row) { self.commit() }
                        return false
                    }
                    return true
                }
                if event.window !== self.panel {
                    let isAnchor = self.anchor.map { anchor in
                        event.window === anchor.window && anchor.bounds.contains(anchor.convert(event.locationInWindow, from: nil))
                    } ?? false
                    self.dismiss()
                    // A second click on the button closes it instead of reopening.
                    return !isAnchor
                }
                return true
            }
            return forwardEvent ? event : nil
        }
        let notifications: [(Notification.Name, AnyObject)] = [
            (NSApplication.didResignActiveNotification, NSApp),
            (NSWindow.willCloseNotification, parent),
            (NSWindow.didMoveNotification, parent),
            (NSWindow.didResizeNotification, parent)
        ]
        for (name, object) in notifications {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.dismiss() }
            })
        }
    }

    private func reload() {
        visible = state.matches
        table.reloadData()
        let hasQuery = !state.query.isEmpty
        let queryHeight: CGFloat = hasQuery ? rowHeight + (visible.isEmpty ? 0 : 5) : 0
        let screen = anchor?.window?.screen?.visibleFrame ?? NSScreen.main!.visibleFrame
        let availableHeight = min(320, screen.height - 16)
        let listHeight = min(CGFloat(visible.count) * rowHeight, availableHeight - queryHeight - padding * 2)
        let height = max(rowHeight + padding * 2, listHeight + queryHeight + padding * 2)
        let y = max(screen.minY + 4, topEdge - height)
        panel.setFrame(NSRect(x: panel.frame.minX, y: y, width: menuWidth, height: height), display: true)
        background.frame = NSRect(x: 0, y: 0, width: menuWidth, height: height)
        // Keep a real, attached text view even before the first character. Its
        // zero-height frame hides the search row without disabling text input.
        editor.frame = NSRect(x: 24, y: padding + 3, width: menuWidth - 36, height: hasQuery ? rowHeight - 4 : 0)
        editor.textColor = .secondaryLabelColor
        editor.setAccessibilityHelp(visible.isEmpty ? "No matches. Delete text to broaden the filter." : "\(visible.count) matching choices")
        divider.isHidden = !hasQuery || visible.isEmpty
        divider.frame = NSRect(x: 8, y: padding + queryHeight - 3, width: menuWidth - 16, height: 1)
        scroll.isHidden = visible.isEmpty
        scroll.frame = NSRect(x: 0, y: padding + queryHeight, width: menuWidth, height: listHeight)
        table.frame = NSRect(x: 0, y: 0, width: menuWidth, height: CGFloat(visible.count) * rowHeight)
        table.tableColumns.first?.width = menuWidth
        emptyLabel.isHidden = !visible.isEmpty || hasQuery
        emptyLabel.frame = NSRect(x: 24, y: padding + 3, width: menuWidth - 36, height: rowHeight)
        updateHighlight(scrollToSelection: true)
        panel.invalidateShadow()
    }

    func textDidChange(_ notification: Notification) {
        state.filter(editor.string)
        reload()
        let announcement = visible.isEmpty ? "No matches for \(state.query)" : "\(visible.count) matches"
        NSAccessibility.post(element: editor, notification: .announcementRequested, userInfo: [
            .announcement: announcement, .priority: NSAccessibilityPriorityLevel.medium.rawValue
        ])
    }

    private func highlight(_ row: Int) {
        state.highlight(visible.indices.contains(row) ? visible[row].id : nil)
        updateHighlight(scrollToSelection: false)
    }

    private func updateHighlight(scrollToSelection: Bool) {
        if let row = visible.firstIndex(where: { $0.id == state.highlightedID }) {
            table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            if scrollToSelection { table.scrollRowToVisible(row) }
        } else { table.deselectAll(nil) }
        let displayedRows = table.rows(in: table.visibleRect)
        guard displayedRows.location != NSNotFound else { return }
        for row in displayedRows.location..<NSMaxRange(displayedRows) where visible.indices.contains(row) {
            guard let cell = table.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTableCellView else { continue }
            let selected = visible[row].id == state.highlightedID
            cell.textField?.textColor = selected ? .selectedMenuItemTextColor : .labelColor
            cell.imageView?.contentTintColor = selected ? .selectedMenuItemTextColor : .labelColor
        }
    }

    private func commit() {
        guard !editor.hasMarkedText(), let id = state.highlightedID, visible.contains(where: { $0.id == id }) else { return }
        let select = onSelect
        dismiss()
        select?(id)
    }

    func numberOfRows(in tableView: NSTableView) -> Int { visible.count }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? { MenuRow() }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let option = visible[row]
        let cell = MenuCell(frame: NSRect(x: 0, y: 0, width: menuWidth, height: rowHeight))
        let text = NSTextField(labelWithString: option.title)
        text.font = .menuFont(ofSize: 0)
        text.lineBreakMode = .byTruncatingTail
        text.translatesAutoresizingMaskIntoConstraints = false
        text.textColor = option.id == state.highlightedID ? .selectedMenuItemTextColor : .labelColor
        cell.addSubview(text)
        cell.textField = text
        let check = NSImageView()
        check.translatesAutoresizingMaskIntoConstraints = false
        check.image = option.id == state.selection ? NSImage(systemSymbolName: "checkmark", accessibilityDescription: "Selected") : nil
        check.contentTintColor = text.textColor
        cell.addSubview(check)
        cell.imageView = check
        // Use the label's intrinsic height so the text and symbol share the
        // row's vertical center, without padding from an oversized text frame.
        NSLayoutConstraint.activate([
            text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 24),
            text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -12),
            text.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            check.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 9),
            check.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 11),
            check.heightAnchor.constraint(equalToConstant: 12)
        ])
        cell.setAccessibilityElement(true)
        cell.setAccessibilityRole(.button)
        cell.setAccessibilityLabel(option.title)
        cell.setAccessibilityValue(option.id == state.selection ? "Selected" : "")
        cell.choose = { [weak self] in
            guard let self else { return }
            self.state.highlight(option.id)
            self.commit()
        }
        return cell
    }
}
