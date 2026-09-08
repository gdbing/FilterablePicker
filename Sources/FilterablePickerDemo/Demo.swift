import AppKit
import SwiftUI
import FilterablePicker

private struct Choice: Identifiable {
    let id: String
    var name: String { id }
}

@main
struct FilterablePickerDemo: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Filterable Picker") {
            DemoView()
        }
        .defaultSize(width: 480, height: 330)
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
private final class DemoModel: ObservableObject {
    @Published var selection = "Morning"
    @Published var nativeSelection = "Morning"
    @Published var enabled = true
}

private struct DemoView: View {
    @StateObject private var model = DemoModel()
    private let choices = [
        "Morning", "Late morning", "Noon", "Early afternoon", "Afternoon", "Late afternoon",
        "Evening", "After dinner", "Midnight", "Breakfast", "Café break", "Commute",
        "Daily planning", "Deep work", "Email", "Focus time", "Lunch", "Meeting",
        "Project review", "Reading", "Research", "Short break", "Team check-in", "Writing",
        "Exercise", "Walk", "Dinner", "Personal time", "日本語", "👩🏽‍💻 Focus time"
    ].map(Choice.init)

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("A picker you can type into")
                .font(.title2.weight(.semibold))
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow {
                    Text("Filterable:")
                    FilterablePicker("Time of day", selection: $model.selection, items: choices, title: \.name)
                        .frame(width: 220)
                        .disabled(!model.enabled)
                }
                GridRow {
                    Text("Native reference:")
                    Picker("Native reference", selection: $model.nativeSelection) {
                        ForEach(choices) { Text($0.name).tag($0.id) }
                    }
                    .labelsHidden()
                    .frame(width: 220)
                }
            }
            Text("Selection: \(model.selection)")
                .foregroundStyle(.secondary)
            Text("Open the picker and type ‘aft’. Delete removes a character; ⌘Delete clears the filter. Drag near a menu edge to scroll the long list.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Toggle("Enabled", isOn: $model.enabled)
        }
        .padding(28)
        .frame(width: 440)
    }
}
