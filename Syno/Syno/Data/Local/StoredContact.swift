//
//  StoredContact.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import Foundation
import SwiftData

/// SwiftData에 저장하는 연락처 영속 모델입니다.
@Model
final class StoredContact {
  /// 앱 내부 연락처 식별자입니다.
  @Attribute(.unique) var id: UUID

  /// 연락처 이름입니다.
  var name: String

  /// 연락처 역할 또는 보조 설명입니다.
  var role: String

  /// 회사 또는 소속 정보입니다.
  var company: String

  /// 이메일 주소입니다.
  var email: String

  /// 전화번호입니다.
  var phone: String

  /// 링크드인 또는 URL 정보입니다.
  var linkedInURL: String

  /// 연락처 그룹입니다.
  var group: String

  /// 한 줄 기록입니다.
  var note: String

  /// 프로필 이미지 데이터입니다.
  var profileImageData: Data?

  /// 즐겨찾기 여부입니다.
  var isFavorite: Bool

  /// 사용자 본인의 프로필인지 여부입니다.
  var isMe: Bool = false

  /// 저장 생성 시각입니다.
  var createdAt: Date

  init(
    id: UUID,
    name: String,
    role: String,
    company: String,
    email: String,
    phone: String,
    linkedInURL: String,
    group: String,
    note: String,
    profileImageData: Data?,
    isFavorite: Bool,
    isMe: Bool,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.role = role
    self.company = company
    self.email = email
    self.phone = phone
    self.linkedInURL = linkedInURL
    self.group = group
    self.note = note
    self.profileImageData = profileImageData
    self.isFavorite = isFavorite
    self.isMe = isMe
    self.createdAt = createdAt
  }

  convenience init(contact: Contact) {
    self.init(
      id: contact.id,
      name: contact.name,
      role: contact.role,
      company: contact.company,
      email: contact.email,
      phone: contact.phone,
      linkedInURL: contact.linkedInURL,
      group: contact.group,
      note: contact.note,
      profileImageData: contact.profileImageData,
      isFavorite: contact.isFavorite,
      isMe: contact.isMe
    )
  }
}

extension StoredContact {
  /// 저장된 연락처를 화면에서 사용하는 `Contact` 엔티티로 변환합니다.
  var contact: Contact {
    Contact(
      id: id,
      name: name,
      role: role,
      company: company,
      email: email,
      phone: phone,
      linkedInURL: linkedInURL,
      group: group,
      note: note,
      profileImageData: profileImageData,
      isFavorite: isFavorite,
      isMe: isMe
    )
  }

  /// 화면에서 수정된 `Contact` 값을 저장 모델에 반영합니다.
  func update(with contact: Contact) {
    name = contact.name
    role = contact.role
    company = contact.company
    email = contact.email
    phone = contact.phone
    linkedInURL = contact.linkedInURL
    group = contact.group
    note = contact.note
    profileImageData = contact.profileImageData
    isFavorite = contact.isFavorite
    isMe = contact.isMe
  }
}
