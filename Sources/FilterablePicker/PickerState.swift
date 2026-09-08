import Foundation

struct PickerOption: Equatable {
    let id: AnyHashable
    let title: String
}

/// A highlight is provisional. Only the popup's commit action changes the binding.
struct PickerState {
    var options: [PickerOption]
    var selection: AnyHashable?
    private(set) var query = ""
    private(set) var highlightedID: AnyHashable?

    var matches: [PickerOption] {
        options.filter { query.isEmpty || $0.title.localizedStandardContains(query) }
    }

    init(options: [PickerOption], selection: AnyHashable?) {
        self.options = options
        self.selection = selection
        highlightedID = options.first(where: { $0.id == selection })?.id ?? options.first?.id
    }

    mutating func filter(_ query: String) {
        self.query = query
        reconcileHighlight()
    }

    mutating func reconcileHighlight() {
        let visible = matches
        if !visible.contains(where: { $0.id == highlightedID }) {
            highlightedID = visible.first(where: { $0.id == selection })?.id ?? visible.first?.id
        }
    }

    mutating func highlight(_ id: AnyHashable?) {
        highlightedID = matches.first(where: { $0.id == id })?.id
    }

    mutating func move(_ offset: Int) {
        let visible = matches
        guard !visible.isEmpty else { highlightedID = nil; return }
        let current = visible.firstIndex(where: { $0.id == highlightedID })
        let next = current.map { min(max($0 + offset, 0), visible.count - 1) }
            ?? (offset > 0 ? 0 : visible.count - 1)
        highlightedID = visible[next].id
    }
}
