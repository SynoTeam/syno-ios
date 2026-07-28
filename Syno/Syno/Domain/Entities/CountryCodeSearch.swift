//
//  CountryCodeSearch.swift
//  Syno
//
//  Created by Codex on 7/28/26.
//

import Foundation

/// 국가번호 목록의 검색과 표시 순서를 결정하는 순수 로직입니다.
enum CountryCodeSearch {
  /// 검색어에 맞는 국가번호를 선택 국가 우선, 국가명 알파벳순으로 반환합니다.
  static func results(
    options: [CountryCodeOption],
    query: String,
    selectedCountryCode: String
  ) -> [CountryCodeOption] {
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let queryDigits = ContactPhoneNumberFormatter.digitsOnly(trimmedQuery)

    let filteredOptions = options.filter { option in
      guard !trimmedQuery.isEmpty else {
        return true
      }

      let matchesCountryName = option.countryName.range(
        of: trimmedQuery,
        options: [.caseInsensitive, .anchored]
      ) != nil
      let matchesCountryCode = !queryDigits.isEmpty &&
        ContactPhoneNumberFormatter.digitsOnly(option.code).contains(queryDigits)

      return matchesCountryName || matchesCountryCode
    }

    return filteredOptions.sorted { lhs, rhs in
      if lhs.code == selectedCountryCode {
        return rhs.code != selectedCountryCode
      }
      if rhs.code == selectedCountryCode {
        return false
      }

      return lhs.countryName.localizedCaseInsensitiveCompare(rhs.countryName) == .orderedAscending
    }
  }
}
