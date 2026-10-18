import AppKit
import FilterablePickerAppKit
import Testing

@MainActor
struct FilterablePickerSectionTests {
    /// The filtering menu, with "Fruit: Apple, Banana" and "Vegetables: Carrot".
    private func makeMenu() throws -> NSMenu {
        let menu = try #require(FPCreateNativeFilteringMenu("Food"))
        menu.addItem(.sectionHeader(title: "Fruit"))
        menu.addItem(withTitle: "Apple", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "Banana", action: nil, keyEquivalent: "")
        menu.addItem(.sectionHeader(title: "Vegetables"))
        menu.addItem(withTitle: "Carrot", action: nil, keyEquivalent: "")
        return menu
    }

    private func search(_ menu: NSMenu, for query: String) {
        _ = menu.perform(
            NSSelectorFromString("performSearchWithString:inMenu:"), with: query, with: menu)
    }

    private func visibleTitles(_ menu: NSMenu) -> [String] {
        menu.items.filter { !$0.isHidden }.map(\.title)
    }

    @Test(
        "A header shows only while one of its items matches",
        .enabled(if: FPIsNativeMenuFilteringAvailable()))
    func headerFollowsItsItems() throws {
        let menu = try makeMenu()

        search(menu, for: "an")

        #expect(visibleTitles(menu) == ["Fruit", "Banana"])
    }

    @Test(
        "Matching a header's title shows every item in its section",
        .enabled(if: FPIsNativeMenuFilteringAvailable()))
    func headerTitleShowsItsSection() throws {
        let menu = try makeMenu()

        search(menu, for: "veg")

        #expect(visibleTitles(menu) == ["Vegetables", "Carrot"])
    }

    @Test(
        "An empty query shows everything again",
        .enabled(if: FPIsNativeMenuFilteringAvailable()))
    func emptyQueryResets() throws {
        let menu = try makeMenu()

        search(menu, for: "zzz")
        #expect(visibleTitles(menu).isEmpty)
        search(menu, for: "")

        #expect(visibleTitles(menu) == ["Fruit", "Apple", "Banana", "Vegetables", "Carrot"])
    }
}
