import Foundation
import Testing
@testable import FilterablePicker

@Suite struct OpeningClickTests {
    @Test func openingReleaseDoesNotChooseTheOverlappingRow() {
        var click = OpeningClick(origin: CGPoint(x: 100, y: 100))
        #expect(click.isTracking)
        let ignoresOpeningRelease = click.shouldIgnoreRelease(at: CGPoint(x: 101, y: 100))
        #expect(ignoresOpeningRelease)
        #expect(!click.isTracking)
        // The next click is a deliberate choice, even at the same location.
        let ignoresNextRelease = click.shouldIgnoreRelease(at: CGPoint(x: 101, y: 100))
        #expect(!ignoresNextRelease)
    }

    @Test func draggingIntoTheMenuCanChooseOnRelease() {
        var click = OpeningClick(origin: CGPoint(x: 100, y: 100))
        click.dragged(to: CGPoint(x: 100, y: 140))
        let ignoresRelease = click.shouldIgnoreRelease(at: CGPoint(x: 100, y: 140))
        #expect(!ignoresRelease)
    }

    @Test func draggingBackToTheOriginalItemCanChooseIt() {
        var click = OpeningClick(origin: CGPoint(x: 100, y: 100))
        click.dragged(to: CGPoint(x: 100, y: 140))
        let ignoresRelease = click.shouldIgnoreRelease(at: CGPoint(x: 100, y: 100))
        #expect(!ignoresRelease)
    }

    @Test func keyboardAndAccessibilityOpeningDoNotConsumeTheNextClick() {
        var click = OpeningClick(origin: nil)
        #expect(!click.isTracking)
        let ignoresRelease = click.shouldIgnoreRelease(at: CGPoint(x: 100, y: 100))
        #expect(!ignoresRelease)
    }
}
