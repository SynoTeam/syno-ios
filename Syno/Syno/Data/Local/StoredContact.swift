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
  var id: UUID = UUID()

  /// 연락처 이름입니다.
  var name: String = ""

  /// 연락처 역할 또는 보조 설명입니다.
  var role: String = ""

  /// 회사 또는 소속 정보입니다.
  var company: String = ""

  /// 이메일 주소입니다.
  var email: String = ""

  /// 전화번호입니다.
  var phone: String = ""

  /// 웹사이트 또는 프로필 URL 정보입니다.
  var url: String = ""

  /// 연락처 주소입니다.
  var address: String = ""

  /// 생일입니다.
  var birthday: Date?

  /// 기념일입니다.
  var anniversary: Date?

  /// 소셜 플랫폼별 사용자 식별자 목록입니다.
  var socialLinks: [ContactSocialLink] = []

  /// 연락처 그룹입니다.
  var group: String = ""

  /// 한 줄 기록입니다.
  var note: String = ""

  /// 프로필 이미지 데이터입니다.
  var profileImageData: Data?

  /// 즐겨찾기 여부입니다.
  var isFavorite: Bool = false

  /// 노트 목록 상단에 고정할지 여부입니다.
  var isPinned: Bool = false

  /// 사용자 본인의 프로필인지 여부입니다.
  var isMe: Bool = false

  /// 저장 생성 시각입니다.
  var createdAt: Date = Date()

  init(
    id: UUID,
    name: String,
    role: String,
    company: String,
    email: String,
    phone: String,
    url: String,
    address: String,
    birthday: Date?,
    anniversary: Date?,
    socialLinks: [ContactSocialLink],
    group: String,
    note: String,
    profileImageData: Data?,
    isFavorite: Bool,
    isPinned: Bool = false,
    isMe: Bool,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.role = role
    self.company = company
    self.email = email
    self.phone = phone
    self.url = url
    self.address = address
    self.birthday = birthday
    self.anniversary = anniversary
    self.socialLinks = socialLinks
    self.group = group
    self.note = note
    self.profileImageData = profileImageData
    self.isFavorite = isFavorite
    self.isPinned = isPinned
    self.isMe = isMe
    self.createdAt = createdAt
  }
}
