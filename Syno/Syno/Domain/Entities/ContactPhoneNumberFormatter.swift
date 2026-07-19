//
//  ContactPhoneNumberFormatter.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import Foundation

/// 연락처 폼에서 사용하는 국가번호와 전화번호 문자열 변환 유틸리티입니다.
enum ContactPhoneNumberFormatter {
  /// 전화번호가 입력된 경우 국가번호와 전화번호를 합친 문자열을 반환합니다.
  static func formatted(countryCode: String, phone: String) -> String {
    let phone = trimmed(phone)
    guard !phone.isEmpty else {
      return ""
    }

    return "\(countryCode) \(phone)"
  }

  /// 저장된 전화번호 문자열을 국가번호와 전화번호로 분리합니다.
  static func split(
    _ phone: String,
    countryCodeOptions: [CountryCodeOption],
    defaultCountryCode: String = "+82"
  ) -> (countryCode: String, phone: String) {
    let trimmedPhone = trimmed(phone)
    guard !trimmedPhone.isEmpty else {
      return (defaultCountryCode, "")
    }

    for option in countryCodeOptions where trimmedPhone.hasPrefix(option.code) {
      let phoneNumber = trimmedPhone
        .dropFirst(option.code.count)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      return (option.code, phoneNumber)
    }

    return (defaultCountryCode, trimmedPhone)
  }

  private static func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
