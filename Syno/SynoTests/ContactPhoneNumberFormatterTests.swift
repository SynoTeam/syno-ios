import XCTest
@testable import Syno

final class ContactPhoneNumberFormatterTests: XCTestCase {
  func testDigitsOnlyRemovesHyphensAndWhitespace() {
    XCTAssertEqual(
      ContactPhoneNumberFormatter.digitsOnly("010 - 1234  - 5678"),
      "01012345678"
    )
  }

  func testHyphenatedFormatsElevenDigitPhoneNumber() {
    XCTAssertEqual(
      ContactPhoneNumberFormatter.hyphenated("01012345678"),
      "010-1234-5678"
    )
  }

  func testHyphenatedFormatsTenDigitPhoneNumber() {
    XCTAssertEqual(
      ContactPhoneNumberFormatter.hyphenated("0111234567"),
      "011-123-4567"
    )
  }

  func testFormattedStoresPhoneWithoutHyphens() {
    XCTAssertEqual(
      ContactPhoneNumberFormatter.formatted(countryCode: "+82", phone: "010-1234-5678"),
      "+82 01012345678"
    )
  }

  func testDisplayFormattedAddsHyphensToStoredPhone() {
    XCTAssertEqual(
      ContactPhoneNumberFormatter.displayFormatted("+82 01012345678"),
      "+82 010-1234-5678"
    )
  }

  func testDisplayFormattedReturnsEmptyStringForEmptyInput() {
    XCTAssertEqual(ContactPhoneNumberFormatter.displayFormatted(""), "")
  }
}
