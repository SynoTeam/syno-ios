import XCTest
@testable import Syno

final class StaticLabelDictionaryTests: XCTestCase {
  func testBundledDictionaryLoadsKnownLabelsAndLeavesUnknownLabelsUnmapped() {
    let dictionary = StaticLabelDictionary()

    XCTAssertEqual(dictionary.translation(for: "cat"), "고양이")
    XCTAssertEqual(dictionary.translation(for: " CAT "), "고양이")
    XCTAssertEqual(dictionary.translation(for: "tableware"), "식기")
    XCTAssertEqual(dictionary.translation(for: "german_shepherd"), "저먼 셰퍼드")
    XCTAssertEqual(dictionary.translation(for: "fried_chicken"), "치킨")
    XCTAssertEqual(dictionary.translation(for: "blue_sky"), "파란 하늘")
    XCTAssertEqual(dictionary.translation(for: "laundry_machine"), "세탁기")
    XCTAssertEqual(dictionary.translation(for: "traffic_light"), "신호등")
    XCTAssertEqual(dictionary.translation(for: "computer_monitor"), "모니터")
    XCTAssertEqual(dictionary.translation(for: "printed_page"), "인쇄물")
    XCTAssertEqual(dictionary.translation(for: "train_station"), "기차역")
    XCTAssertNil(dictionary.translation(for: "unmapped_label"))
    XCTAssertEqual(
      dictionary.searchTerms(for: ["cat", "unmapped_label"]),
      ["cat", "고양이", "unmapped_label"]
    )
  }
}
