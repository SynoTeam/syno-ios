//
//  ContactPhoneNumberFormatter.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import Foundation

/// 연락처 폼에서 사용하는 국가번호와 전화번호 문자열 변환 유틸리티입니다.
enum ContactPhoneNumberFormatter {
  /// 문자열에서 숫자만 추출합니다.
  static func digitsOnly(_ value: String) -> String {
    value.compactMap(\.wholeNumberValue).map(String.init).joined()
  }

  /// 국내 전화번호 자릿수에 맞춰 하이픈을 포함한 표시 문자열을 반환합니다.
  static func hyphenated(_ digits: String) -> String {
    let digits = digitsOnly(digits)

    switch digits.count {
    case ...3:
      return digits
    case 4...9:
      return "\(digits.prefix(3))-\(digits.dropFirst(3))"
    case 10:
      return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
    default:
      return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(4))-\(digits.dropFirst(7))"
    }
  }

  /// 저장된 전화번호 문자열(국가번호 + 숫자)을 하이픈 포함 표시용 문자열로 변환합니다.
  static func displayFormatted(_ storedPhone: String) -> String {
    let trimmedPhone = trimmed(storedPhone)
    guard !trimmedPhone.isEmpty else {
      return ""
    }

    guard let spaceIndex = trimmedPhone.firstIndex(of: " ") else {
      return hyphenated(trimmedPhone)
    }

    let countryCode = trimmedPhone[..<spaceIndex]
    let digits = trimmedPhone[trimmedPhone.index(after: spaceIndex)...]
    return "\(countryCode) \(hyphenated(String(digits)))"
  }

  /// 전화번호가 입력된 경우 국가번호와 전화번호를 합친 문자열을 반환합니다.
  static func formatted(countryCode: String, phone: String) -> String {
    let phone = digitsOnly(phone)
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
      return (option.code, digitsOnly(phoneNumber))
    }

    return (defaultCountryCode, digitsOnly(trimmedPhone))
  }

  private static func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
