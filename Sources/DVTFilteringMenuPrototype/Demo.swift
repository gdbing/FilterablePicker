import AppKit
import DVTFilteringMenuSupport
import FilterablePicker
import SwiftUI

private struct Choice: Identifiable {
    let id: String
}

@main
private struct DVTFilteringMenuPrototypeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("DVTFilteringMenu Comparison") {
            ComparisonView()
        }
        .defaultSize(width: 560, height: 440)
        .windowResizability(.contentSize)
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@MainActor
private final class ComparisonModel: ObservableObject {
    @Published var customSelection = "Morning"
    @Published var appKitSelection = "Morning"
    @Published var dvtSelection = "Morning"
    @Published var swiftUISelection = "Morning"
}

private struct ComparisonView: View {
    @StateObject private var model = ComparisonModel()

    private let choices = [
        "Morning", "Late morning", "Noon", "Early afternoon", "Afternoon", "Late afternoon",
        "Evening", "After dinner", "Midnight", "Breakfast", "Café break", "Commute",
        "Daily planning", "Deep work", "Email", "Focus time", "Lunch", "Meeting",
        "Project review", "Reading", "Research", "Short break", "Team check-in", "Writing",
        "Exercise", "Walk", "Dinner", "Personal time", "日本語", "👩🏽‍💻 Focus time"
    ].map(Choice.init)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Filterable picker comparison")
                .font(.title2.weight(.semibold))

            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 16) {
                GridRow {
                    Text("SwiftUI Picker:")
                    Picker("SwiftUI Picker", selection: $model.swiftUISelection) {
                        ForEach(choices) { choice in
                            Text(choice.id).tag(choice.id)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 270)
                }
                GridRow {
                    Text("Current panel:")
                    FilterablePicker(
                        "Current panel",
                        selection: $model.customSelection,
                        items: choices,
                        title: \.id
                    )
                    .frame(width: 270)
                }
                GridRow {
                    Text("Private AppKit:")
                    AppKitFilteringPicker(
                        selection: $model.appKitSelection,
                        choices: choices.map(\.id)
                    )
                    .frame(width: 270)
                }
                GridRow {
                    Text("Xcode DVT menu:")
                    DVTFilteringPicker(
                        selection: $model.dvtSelection,
                        choices: choices.map(\.id)
                    )
                    .frame(width: 270)
                }
            }

            Text("Open each picker and type ‘aft’. Private AppKit uses NSMenu’s private native filtering UI; Xcode DVT loads DVTKit. Neither private prototype should ship through the App Store.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("SwiftUI: \(model.swiftUISelection)    Current: \(model.customSelection)\nAppKit: \(model.appKitSelection)    DVT: \(model.dvtSelection)")
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 520)
    }
}

private struct AppKitFilteringPicker: NSViewRepresentable {
    @Binding var selection: String
    let choices: [String]

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        context.coordinator.button = button
        context.coordinator.configure(choices: choices, selection: selection)
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        context.coordinator.onSelect = { selection = $0 }
        context.coordinator.update(choices: choices, selection: selection)
    }

    @MainActor
    final class Coordinator: NSObject {
        weak var button: NSPopUpButton?
        var onSelect: ((String) -> Void)?

        private var choiceItems: [NSMenuItem] = []
        private var configuredChoices: [String] = []
        private var hooksUnavailable = false

        func configure(choices: [String], selection: String) {
            guard let button else { return }
            guard let menu = CreateAppKitFilteringMenu("Choices") else {
                hooksUnavailable = true
                button.removeAllItems()
                button.addItem(withTitle: "Private AppKit hooks unavailable")
                button.isEnabled = false
                return
            }

            button.menu = menu
            configuredChoices = choices
            populate(menu: menu, choices: choices, selection: selection)
        }

        func update(choices: [String], selection: String) {
            guard !hooksUnavailable, let menu = button?.menu else { return }
            if choices != configuredChoices {
                configuredChoices = choices
                for item in choiceItems { menu.removeItem(item) }
                populate(menu: menu, choices: choices, selection: selection)
            } else {
                for item in choiceItems {
                    item.state = item.representedObject as? String == selection ? .on : .off
                }
                button?.selectItem(withTitle: selection)
            }
        }

        private func populate(menu: NSMenu, choices: [String], selection: String) {
            choiceItems = choices.map { title in
                let item = NSMenuItem(title: title, action: #selector(choose(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = title
                item.state = title == selection ? .on : .off
                menu.addItem(item)
                return item
            }
            button?.selectItem(withTitle: selection)
        }

        @objc private func choose(_ sender: NSMenuItem) {
            guard let title = sender.representedObject as? String else { return }
            for item in choiceItems { item.state = item === sender ? .on : .off }
            button?.select(sender)
            onSelect?(title)
        }
    }
}

private struct DVTFilteringPicker: NSViewRepresentable {
    @Binding var selection: String
    let choices: [String]

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        context.coordinator.button = button
        context.coordinator.configure(choices: choices, selection: selection)
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        context.coordinator.onSelect = { selection = $0 }
        context.coordinator.update(choices: choices, selection: selection)
    }

    @MainActor
    final class Coordinator: NSObject, NSMenuDelegate {
        weak var button: NSPopUpButton?
        var onSelect: ((String) -> Void)?

        private var choiceItems: [NSMenuItem] = []
        private var configuredChoices: [String] = []
        private var loadFailure: String?

        func configure(choices: [String], selection: String) {
            guard let button else { return }
            do {
                let menuClass: AnyClass = try DVTKitLoader.menuClass()
                guard let menu = CreateDVTFilteringMenu(menuClass, "Choices", true) else {
                    throw PrototypeError("DVTFilteringMenu initialization failed")
                }
                menu.setValue(true, forKey: "initiallyShowsSearch")
                menu.delegate = self
                button.menu = menu
                configuredChoices = choices
                populate(menu: menu, choices: choices, selection: selection)
            } catch {
                loadFailure = error.localizedDescription
                button.removeAllItems()
                button.addItem(withTitle: "DVTKit unavailable")
                button.isEnabled = false
                button.toolTip = error.localizedDescription
            }
        }

        func update(choices: [String], selection: String) {
            guard loadFailure == nil, let menu = button?.menu else { return }
            if choices != configuredChoices {
                configuredChoices = choices
                for item in choiceItems { menu.removeItem(item) }
                populate(menu: menu, choices: choices, selection: selection)
            } else {
                for item in choiceItems { item.state = item.representedObject as? String == selection ? .on : .off }
                button?.selectItem(withTitle: selection)
            }
        }

        private func populate(menu: NSMenu, choices: [String], selection: String) {
            choiceItems = choices.map { title in
                let item = NSMenuItem(title: title, action: #selector(choose(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = title
                item.state = title == selection ? .on : .off
                menu.addItem(item)
                return item
            }
            button?.selectItem(withTitle: selection)
        }

        @objc private func choose(_ sender: NSMenuItem) {
            guard let title = sender.representedObject as? String else { return }
            for item in choiceItems { item.state = item === sender ? .on : .off }
            button?.select(sender)
            onSelect?(title)
        }

        /// Required by Xcode's private DVTFilteringMenuDelegate protocol.
        @objc(filterItems:inMenu:forSearchString:)
        private func filterItems(_ items: [NSMenuItem], in menu: NSMenu, forSearchString query: String) {
            for item in items {
                item.isHidden = !query.isEmpty && !item.title.localizedStandardContains(query)
            }
        }

    }
}

@MainActor
private enum DVTKitLoader {
    static func menuClass() throws -> AnyClass {
        if let existing = NSClassFromString("DVTFilteringMenu") { return existing }

        let environmentPath = ProcessInfo.processInfo.environment["DVTKIT_FRAMEWORK_PATH"]
        let candidates = [
            environmentPath,
            "/Applications/Xcode-beta.app/Contents/SharedFrameworks/DVTKit.framework",
            "/Applications/Xcode.app/Contents/SharedFrameworks/DVTKit.framework"
        ].compactMap { $0 }

        for path in candidates where FileManager.default.fileExists(atPath: path) {
            guard let bundle = Bundle(path: path) else { continue }
            do {
                try bundle.loadAndReturnError()
                if let menuClass = NSClassFromString("DVTFilteringMenu") { return menuClass }
            } catch {
                continue
            }
        }
        throw PrototypeError("Could not load DVTFilteringMenu from Xcode or Xcode-beta")
    }
}

private struct PrototypeError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
