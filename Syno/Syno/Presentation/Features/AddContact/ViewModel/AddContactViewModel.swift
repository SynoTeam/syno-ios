//
//  AddContactViewModel.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import Foundation
import Observation

/// 연락처 추가 화면에서 선택할 수 있는 국가번호 옵션입니다.
struct CountryCodeOption: Identifiable, Hashable {
  /// 실제 전화번호에 붙는 국가번호입니다.
  let code: String

  /// 국가번호 목록에 표시할 국가 이름입니다.
  let countryName: String

  /// 국가번호 옵션의 고유 식별자입니다.
  var id: String {
    code
  }

  /// 국가 이름과 국가번호를 함께 보여주는 표시 문자열입니다.
  var displayTitle: String {
    "\(countryName) \(code)"
  }
}

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
    CountryCodeOption(code: "+44", countryName: "영국")
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
  
  /// 현재 폼 상태를 저장 가능한 `Contact` 엔티티로 변환합니다.
  func makeContact() -> Contact {
    Contact(
      name: contactName,
      role: trimmed(email),
      company: "",
      email: trimmed(email),
      phone: formattedPhone,
      linkedInURL: trimmed(linkedInURL),
      group: group,
      note: trimmed(note),
      profileImageData: selectedImageData
    )
  }
  
  private func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// 전화번호가 입력된 경우 국가번호와 전화번호를 합친 문자열입니다.
  private var formattedPhone: String {
    let phone = trimmed(phone)
    guard !phone.isEmpty else {
      return ""
    }

    return "\(countryCode) \(phone)"
  }
}
