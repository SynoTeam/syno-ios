import XCTest
@testable import Syno

final class CountryCodeSearchTests: XCTestCase {
  private let options = [
    CountryCodeOption(code: "+82", countryName: "Korea"),
    CountryCodeOption(code: "+1", countryName: "America"),
    CountryCodeOption(code: "+81", countryName: "Japan")
  ]

  func testResultsMatchesCountryNamePrefixIgnoringCase() {
    let results = CountryCodeSearch.results(
      options: options,
      query: "ja",
      selectedCountryCode: "+82"
    )

    XCTAssertEqual(results, [CountryCodeOption(code: "+81", countryName: "Japan")])
  }

  func testResultsMatchesCountryCodeDigits() {
    let results = CountryCodeSearch.results(
      options: options,
      query: "82",
      selectedCountryCode: "+1"
    )

    XCTAssertEqual(results, [CountryCodeOption(code: "+82", countryName: "Korea")])
  }

  func testResultsPlacesSelectedCountryFirstThenSortsByCountryName() {
    let results = CountryCodeSearch.results(
      options: options,
      query: "",
      selectedCountryCode: "+81"
    )

    XCTAssertEqual(results.map(\.code), ["+81", "+1", "+82"])
  }
}
