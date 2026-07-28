import XCTest
@testable import Syno

final class GroupOptionsTests: XCTestCase {
  func testMergedCombinesAndSortsExistingAndDraftGroups() {
    let groups = GroupOptions.merged(
      existingGroups: ["Portfolio", "Gamma", "Beta", "Alpha"],
      draftGroup: "Delta"
    )

    XCTAssertEqual(groups, ["Alpha", "Beta", "Delta", "Gamma", "Portfolio"])
  }

  func testMergedRemovesWhitespaceAndCaseInsensitiveDuplicates() {
    let groups = GroupOptions.merged(
      existingGroups: ["Portfolio", "", " portfolio ", "스터디", "   "],
      draftGroup: "STUDY"
    )

    XCTAssertEqual(groups, ["스터디", "Portfolio", "STUDY"])
  }

  func testMatchingGroupReturnsExistingGroupWithoutCaseSensitivity() {
    let match = GroupOptions.matchingGroup(
      for: "portfolio",
      in: ["Portfolio", "스터디"]
    )

    XCTAssertEqual(match, "Portfolio")
  }
}
