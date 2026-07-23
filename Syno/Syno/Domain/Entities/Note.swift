//
//  Note.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import Foundation

/// 연락처에 남긴 메모를 나타내는 도메인 모델입니다.
struct Note: Identifiable, Equatable {
  let id: UUID
  var contactId: UUID?
  var contactName: String
  var content: String
  var createdAt: Date
  var imageData: Data?
  var profileImageData: Data?
  var isFavorite: Bool

  var timeText: String {
    createdAt.formatted(date: .omitted, time: .shortened)
  }

  var contact: Contact {
    Contact(
      id: contactId ?? id,
      name: contactName,
      role: "",
      company: "",
      profileImageData: profileImageData
    )
  }

  init(
    id: UUID = UUID(),
    contactId: UUID? = nil,
    contactName: String,
    content: String,
    createdAt: Date = Date(),
    imageData: Data? = nil,
    profileImageData: Data? = nil,
    isFavorite: Bool = false
  ) {
    self.id = id
    self.contactId = contactId
    self.contactName = contactName
    self.content = content
    self.createdAt = createdAt
    self.imageData = imageData
    self.profileImageData = profileImageData
    self.isFavorite = isFavorite
  }
}
