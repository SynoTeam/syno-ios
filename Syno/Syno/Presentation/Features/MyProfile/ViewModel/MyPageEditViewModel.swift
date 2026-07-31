//
//  MyPageEditViewModel.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import Foundation
import Observation

/// 내 프로필 편집 화면의 입력 상태와 수정된 `Contact` 생성을 담당하는 ViewModel입니다.
@MainActor
@Observable
final class MyPageEditViewModel {
  /// 한 줄 기록에 허용되는 최대 글자 수입니다.
  static let noteLimit = AddContactViewModel.noteLimit

  private let originalContact: Contact

  var familyName = ""
  var givenName = ""
  var email = ""
  var countryCode = "+82"
  var phone = ""
  var url = ""
  var address = ""
  var birthday: Date?
  var anniversary: Date?
  var socialLinks: [ContactSocialLink] = []
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

  /// 성과 이름을 합쳐 만든 내 프로필 이름입니다.
  var contactName: String {
    "\(trimmed(familyName))\(trimmed(givenName))"
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  init(contact: Contact) {
    originalContact = contact

    let nameParts = Self.splitName(contact.name)
    familyName = nameParts.familyName
    givenName = nameParts.givenName
    email = contact.email
    url = contact.url
    address = contact.address
    birthday = contact.birthday
    anniversary = contact.anniversary
    socialLinks = contact.socialLinks
    group = contact.group
    selectedImageData = contact.profileImageData
    note = contact.note

    let phoneParts = ContactPhoneNumberFormatter.split(
      contact.phone,
      countryCodeOptions: AddContactViewModel.countryCodeOptions
    )
    countryCode = phoneParts.countryCode
    phone = phoneParts.phone
  }

  /// 선택된 그룹 값을 폼 상태에 반영합니다.
  func selectGroup(_ group: String) {
    self.group = group
  }

  /// 선택된 국가번호 값을 폼 상태에 반영합니다.
  func selectCountryCode(_ countryCode: String) {
    self.countryCode = countryCode
  }

  /// 현재 편집 상태를 기존 Contact 식별자를 유지한 새 `Contact`로 변환합니다.
  func makeContact() -> Contact {
    Contact(
      id: originalContact.id,
      name: contactName,
      role: originalContact.role,
      company: originalContact.company,
      email: trimmed(email),
      phone: ContactPhoneNumberFormatter.formatted(countryCode: countryCode, phone: phone),
      url: trimmed(url),
      address: trimmed(address),
      birthday: birthday,
      anniversary: anniversary,
      socialLinks: socialLinks,
      group: group,
      note: trimmed(note),
      profileImageData: selectedImageData,
      isFavorite: originalContact.isFavorite,
      isMe: originalContact.isMe
    )
  }

  private func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func splitName(_ name: String) -> (familyName: String, givenName: String) {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
      return ("", "")
    }

    let parts = trimmedName.split(separator: " ", maxSplits: 1).map(String.init)
    if parts.count == 2 {
      return (parts[0], parts[1])
    }

    guard let firstCharacter = trimmedName.first, trimmedName.count > 1 else {
      return (trimmedName, "")
    }

    return (String(firstCharacter), String(trimmedName.dropFirst()))
  }
}
