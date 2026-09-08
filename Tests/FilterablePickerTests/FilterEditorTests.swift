import AppKit
import Testing
@testable import FilterablePicker

@Suite(.serialized) @MainActor struct FilterEditorTests {
    @Test func editorInitializationCreatesACompleteTextSystem() {
        let editor = FilterEditor()
        #expect(editor.textStorage != nil)
        #expect(editor.layoutManager?.textStorage === editor.textStorage)
        #expect(editor.textContainer?.layoutManager === editor.layoutManager)
    }

    @Test func nativeDeletionCommands() {
        let editor = FilterEditor()
        editor.insertText("aft", replacementRange: NSRange(location: NSNotFound, length: 0))
        editor.doCommand(by: #selector(NSResponder.deleteBackward(_:)))
        #expect(editor.string == "af")
        editor.doCommand(by: #selector(NSResponder.deleteToBeginningOfLine(_:)))
        #expect(editor.string.isEmpty)
        editor.insertText("late afternoon", replacementRange: NSRange(location: NSNotFound, length: 0))
        editor.doCommand(by: #selector(NSResponder.deleteWordBackward(_:)))
        #expect(editor.string == "late ")
    }

    @Test func deletionPreservesComposedCharacters() {
        let editor = FilterEditor()
        editor.insertText("a👩🏽‍💻", replacementRange: NSRange(location: NSNotFound, length: 0))
        editor.doCommand(by: #selector(NSResponder.deleteBackward(_:)))
        #expect(editor.string == "a")
    }

    @Test func cursorMovementDoesNotChangeInsertionPosition() {
        let editor = FilterEditor()
        editor.insertText("af", replacementRange: NSRange(location: NSNotFound, length: 0))
        editor.doCommand(by: #selector(NSResponder.moveLeft(_:)))
        editor.doCommand(by: #selector(NSResponder.moveToBeginningOfLine(_:)))
        editor.insertText("t", replacementRange: NSRange(location: NSNotFound, length: 0))
        #expect(editor.string == "aft")
    }

    @Test func markedTextCanBeReplacedAndCommitted() {
        let editor = FilterEditor()
        editor.setMarkedText("に", selectedRange: NSRange(location: 1, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
        #expect(editor.hasMarkedText())
        editor.setMarkedText("にほん", selectedRange: NSRange(location: 3, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
        editor.insertText("日本", replacementRange: NSRange(location: NSNotFound, length: 0))
        #expect(editor.string == "日本")
        #expect(!editor.hasMarkedText())
    }

    @Test func multilineInsertionStaysOnOneLine() {
        let editor = FilterEditor()
        editor.insertText("late\nafternoon", replacementRange: NSRange(location: NSNotFound, length: 0))
        #expect(editor.string == "late afternoon")
    }
}
