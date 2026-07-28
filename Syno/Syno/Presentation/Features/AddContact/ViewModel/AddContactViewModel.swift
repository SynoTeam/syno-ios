//
//  AddContactViewModel.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import Contacts
import Foundation
import Observation

/// 연락처 추가 폼의 입력 상태와 저장용 `Contact` 생성을 담당하는 ViewModel입니다.
@MainActor
@Observable
final class AddContactViewModel {
  /// 한 줄 기록에 허용되는 최대 글자 수입니다.
  static let noteLimit = 100

  /// 그룹 선택 시트에 표시할 기본 그룹 목록입니다.
  static let groupOptions = ["포트폴리오", "커피챗", "채용", "기타"]

  /// 국가번호 선택 시트에 표시할 기본 국가번호 목록입니다.
  static let countryCodeOptions = [
    CountryCodeOption(code: "+82", countryName: "대한민국"),
    CountryCodeOption(code: "+1", countryName: "미국"),
    CountryCodeOption(code: "+81", countryName: "일본"),
    CountryCodeOption(code: "+86", countryName: "중국"),
    CountryCodeOption(code: "+44", countryName: "영국"),
    CountryCodeOption(code: "+49", countryName: "독일"),
    CountryCodeOption(code: "+33", countryName: "프랑스"),
    CountryCodeOption(code: "+61", countryName: "호주"),
    CountryCodeOption(code: "+91", countryName: "인도"),
    CountryCodeOption(code: "+65", countryName: "싱가포르"),
    CountryCodeOption(code: "+886", countryName: "대만"),
    CountryCodeOption(code: "+84", countryName: "베트남"),
    CountryCodeOption(code: "+66", countryName: "태국"),
    CountryCodeOption(code: "+852", countryName: "홍콩")
  ]
  
  var familyName = ""
  var givenName = ""
  var email = ""
  var countryCode = "+82"
  var phone = ""
  var linkedInURL = ""
  var group = ""
  var selectedImageData: Data?
  var note = "" {
    didSet {
      if note.count > Self.noteLimit {
        note = String(note.prefix(Self.noteLimit))
      }
    }
  }
  
  /// 성 또는 이름 중 하나 이상 입력됐을 때 저장할 수 있는지 여부입니다.
  var canSave: Bool {
    !contactName.isEmpty
  }
  
  /// 성과 이름을 합쳐 만든 연락처 이름입니다.
  var contactName: String {
    "\(trimmed(familyName))\(trimmed(givenName))"
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  /// 선택된 그룹 값을 폼 상태에 반영합니다.
  func selectGroup(_ group: String) {
    self.group = group
  }

  /// 선택된 국가번호 값을 폼 상태에 반영합니다.
  func selectCountryCode(_ countryCode: String) {
    self.countryCode = countryCode
  }

  /// 휴대폰 연락처 선택 결과를 연락처 추가 폼에 반영합니다.
  func applyDeviceContact(_ contact: CNContact) {
    familyName = contact.familyName
    givenName = contact.givenName
    email = contact.emailAddresses.first?.value as String? ?? ""
    linkedInURL = contact.urlAddresses.first?.value as String? ?? ""
    selectedImageData = contact.imageData

    if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
      let phoneParts = ContactPhoneNumberFormatter.split(
        phoneNumber,
        countryCodeOptions: Self.countryCodeOptions
      )
      countryCode = phoneParts.countryCode
      phone = phoneParts.phone
    }
  }
  
  /// 현재 폼 상태를 저장 가능한 `Contact` 엔티티로 변환합니다.
  func makeContact() -> Contact {
    Contact(
      name: contactName,
      role: trimmed(email),
      company: "",
      email: trimmed(email),
      phone: ContactPhoneNumberFormatter.formatted(countryCode: countryCode, phone: phone),
      linkedInURL: trimmed(linkedInURL),
      group: group,
      note: trimmed(note),
      profileImageData: selectedImageData
    )
  }
  
  private func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
