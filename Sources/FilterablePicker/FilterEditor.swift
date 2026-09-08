import AppKit

/// AppKit owns text insertion, composed characters, marked text and key bindings.
/// Outside IME composition this is an append-only field, with no visible caret.
@MainActor
final class FilterEditor: NSTextView {
    var onMove: ((Int) -> Void)?
    var onCommit: (() -> Void)?
    var onCancel: (() -> Void)?
    var onTab: ((Bool) -> Void)?

    override var shouldDrawInsertionPoint: Bool { false }

    init() {
        let storage = NSTextStorage()
        let layout = NSLayoutManager()
        let container = NSTextContainer(containerSize: NSSize(width: 300, height: CGFloat.greatestFiniteMagnitude))
        storage.addLayoutManager(layout)
        layout.addTextContainer(container)
        // Call the designated initializer directly. init(frame:) dispatches back
        // through the subclass's unavailable init(frame:textContainer:) at runtime.
        super.init(frame: NSRect(x: 0, y: 0, width: 300, height: 24), textContainer: container)
        isEditable = true
        isSelectable = true
        isRichText = false
        importsGraphics = false
        drawsBackground = false
        isVerticallyResizable = false
        isHorizontallyResizable = false
        textContainerInset = .zero
        textContainer?.lineFragmentPadding = 0
        textContainer?.maximumNumberOfLines = 1
        textContainer?.lineBreakMode = .byTruncatingHead
        font = .menuFont(ofSize: 0)
        textColor = .secondaryLabelColor
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isContinuousSpellCheckingEnabled = false
        isGrammarCheckingEnabled = false
        isAutomaticLinkDetectionEnabled = false
        isAutomaticDataDetectionEnabled = false
        allowsUndo = false
        setAccessibilityLabel("Filter choices")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func moveInsertionToEnd() {
        if !hasMarkedText() { setSelectedRange(NSRange(location: (string as NSString).length, length: 0)) }
    }

    override func keyDown(with event: NSEvent) {
        moveInsertionToEnd()
        super.keyDown(with: event)
        moveInsertionToEnd()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        moveInsertionToEnd()
    }

    override func resetCursorRects() { addCursorRect(bounds, cursor: .arrow) }

    override func doCommand(by selector: Selector) {
        // An input method gets first refusal in NSTextView.keyDown. Commands that
        // reach here during composition must still use the native text system.
        if hasMarkedText() { super.doCommand(by: selector); return }
        let command = NSStringFromSelector(selector)
        switch command {
        case "moveUp:": onMove?(-1)
        case "moveDown:": onMove?(1)
        case "insertNewline:", "insertNewlineIgnoringFieldEditor:": onCommit?()
        case "cancelOperation:": onCancel?()
        case "insertTab:": onTab?(false)
        case "insertBacktab:": onTab?(true)
        default:
            if command.hasPrefix("move") || command.hasPrefix("select") || command.hasPrefix("insert") {
                return
            }
            moveInsertionToEnd()
            super.doCommand(by: selector)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else { return super.performKeyEquivalent(with: event) }
        if event.charactersIgnoringModifiers?.lowercased() == "v" {
            pasteAsPlainText(nil)
            return true
        }
        if ["a", "c", "x", "z"].contains(event.charactersIgnoringModifiers?.lowercased() ?? "") {
            return true
        }
        // In particular, Command-Delete must reach AppKit's key-binding system.
        if event.keyCode == 51 || event.keyCode == 117 {
            keyDown(with: event)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        let text = (insertString as? NSAttributedString)?.string ?? (insertString as? String) ?? ""
        let singleLine = text.components(separatedBy: .newlines).joined(separator: " ")
        moveInsertionToEnd()
        super.insertText(singleLine, replacementRange: replacementRange)
    }
}
