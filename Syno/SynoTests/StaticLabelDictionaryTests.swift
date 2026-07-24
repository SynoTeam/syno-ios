import XCTest
@testable import Syno

final class StaticLabelDictionaryTests: XCTestCase {
  func testBundledDictionaryLoadsKnownLabelsAndLeavesUnknownLabelsUnmapped() {
    let dictionary = StaticLabelDictionary()

    XCTAssertEqual(dictionary.translation(for: "cat"), "고양이")
    XCTAssertEqual(dictionary.translation(for: " CAT "), "고양이")
    XCTAssertEqual(dictionary.translation(for: "tableware"), "식기")
    XCTAssertNil(dictionary.translation(for: "unmapped_label"))
    XCTAssertEqual(
      dictionary.searchTerms(for: ["cat", "unmapped_label"]),
      ["cat", "고양이", "unmapped_label"]
    )
  }
}
