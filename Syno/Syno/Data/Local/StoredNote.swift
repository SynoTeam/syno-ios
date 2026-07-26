//
//  StoredNote.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import Foundation
import SwiftData

/// SwiftData에 저장하는 노트 영속 모델입니다.
@Model
final class StoredNote {
  /// 앱 내부 노트 식별자입니다.
  var id: UUID = UUID()

  /// 연결된 연락처 식별자입니다.
  var contactId: UUID?

  /// 노트에 표시할 연락처 이름입니다.
  var contactName: String = ""

  /// 노트 본문입니다.
  var content: String = ""

  /// 채팅 기록에 첨부된 이미지 데이터입니다.
  var imageData: Data?

  /// 연락처 프로필 이미지 데이터입니다.
  var profileImageData: Data?

  /// 즐겨찾기 여부입니다.
  var isFavorite: Bool = false

  /// 저장 생성 시각입니다.
  var createdAt: Date = Date()

  init(
    id: UUID,
    contactId: UUID?,
    contactName: String,
    content: String,
    imageData: Data?,
    profileImageData: Data?,
    isFavorite: Bool,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.contactId = contactId
    self.contactName = contactName
    self.content = content
    self.imageData = imageData
    self.profileImageData = profileImageData
    self.isFavorite = isFavorite
    self.createdAt = createdAt
  }

  convenience init(note: Note) {
    self.init(
      id: note.id,
      contactId: note.contactId,
      contactName: note.contactName,
      content: note.content,
      imageData: note.imageData,
      profileImageData: note.profileImageData,
      isFavorite: note.isFavorite,
      createdAt: note.createdAt
    )
  }
}

extension StoredNote {
  func update(with note: Note) {
    contactId = note.contactId
    contactName = note.contactName
    content = note.content
    imageData = note.imageData
    profileImageData = note.profileImageData
    isFavorite = note.isFavorite
    createdAt = note.createdAt
  }

  /// 저장된 노트를 화면에서 사용하는 `Note` 엔티티로 변환합니다.
  var note: Note {
    Note(
      id: id,
      contactId: contactId,
      contactName: contactName,
      content: content,
      createdAt: createdAt,
      imageData: imageData,
      profileImageData: profileImageData,
      isFavorite: isFavorite
    )
  }
}
