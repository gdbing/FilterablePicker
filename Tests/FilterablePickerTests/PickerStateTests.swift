import Testing
@testable import FilterablePicker

@Suite struct PickerStateTests {
    private let options = [
        PickerOption(id: 1, title: "Morning"),
        PickerOption(id: 2, title: "Afternoon"),
        PickerOption(id: 3, title: "Late afternoon"),
        PickerOption(id: 4, title: "Café")
    ]

    @Test func substringFilteringDoesNotCommit() {
        var state = PickerState(options: options, selection: 1)
        state.filter("AFT")
        #expect(state.matches.map(\.id) == [2, 3])
        #expect(state.highlightedID == AnyHashable(2))
        #expect(state.selection == AnyHashable(1))
        state.move(1)
        #expect(state.highlightedID == AnyHashable(3))
        #expect(state.selection == AnyHashable(1))
    }

    @Test func noResultsCannotBecomeASelection() {
        var state = PickerState(options: options, selection: 2)
        state.filter("zzz")
        state.move(1)
        #expect(state.matches.isEmpty)
        #expect(state.highlightedID == nil)
        #expect(state.selection == AnyHashable(2))
        state.filter("")
        #expect(state.highlightedID == AnyHashable(2))
    }

    @Test func diacriticInsensitiveMatching() {
        var state = PickerState(options: options, selection: 1)
        state.filter("cafe")
        #expect(state.matches.map(\.id) == [4])
    }

    @Test func navigationClampsAndRecoversFromNoHighlight() {
        var state = PickerState(options: options, selection: 1)
        state.move(-1)
        #expect(state.highlightedID == AnyHashable(1))
        state.move(100)
        #expect(state.highlightedID == AnyHashable(4))
        state.highlight(nil)
        state.move(-1)
        #expect(state.highlightedID == AnyHashable(4))
        state.options = []
        state.reconcileHighlight()
        #expect(state.highlightedID == nil)
    }

    @Test func duplicateTitlesHaveIndependentIdentity() {
        var state = PickerState(options: [.init(id: 1, title: "Same"), .init(id: 2, title: "Same")], selection: 2)
        state.filter("sam")
        #expect(state.highlightedID == AnyHashable(2))
        #expect(state.matches.count == 2)
    }
}
