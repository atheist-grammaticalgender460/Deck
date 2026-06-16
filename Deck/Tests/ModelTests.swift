import XCTest
@testable import Deck

final class ModelTests: XCTestCase {
    func testProjectCountsByType() {
        let project = Project(name: "Test")
        let bugOpen = Note(status: .pending, type: .bug)
        let bugDone = Note(status: .done, type: .bug)
        let feature = Note(status: .pending, type: .feature)
        bugOpen.project = project
        bugDone.project = project
        feature.project = project
        project.notes = [bugOpen, bugDone, feature]

        XCTAssertEqual(project.pendingCount, 2)
        XCTAssertEqual(project.doneCount, 1)
        let bugCounts = project.counts(for: .bug)
        XCTAssertEqual(bugCounts.pending, 1)
        XCTAssertEqual(bugCounts.done, 1)
    }

    func testRTFDRoundTrip() {
        let original = NSAttributedString(string: "Hello world")
        let data = AttributedContent.data(from: original)
        XCTAssertNotNil(data)
        let restored = AttributedContent.attributedString(from: data)
        XCTAssertEqual(restored.string, "Hello world")
    }
}
