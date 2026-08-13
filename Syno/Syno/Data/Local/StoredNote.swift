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
  var voiceMemoData: Data?
  var voiceMemoDuration: TimeInterval?
  var voiceMemoWaveform: [Float]?
  var fileData: Data?
  var fileName: String?
  var fileSize: Int?

  /// 연락처 프로필 이미지 데이터입니다.
  var profileImageData: Data?

  /// 즐겨찾기 여부입니다.
  var isFavorite: Bool = false

  /// 목록 상단에 고정할지 여부입니다.
  var isPinned: Bool = false

  /// 저장 생성 시각입니다.
  var createdAt: Date = Date()

  init(
    id: UUID,
    contactId: UUID?,
    contactName: String,
    content: String,
    imageData: Data?,
    voiceMemoData: Data? = nil,
    voiceMemoDuration: TimeInterval? = nil,
    voiceMemoWaveform: [Float]? = nil,
    fileData: Data? = nil,
    fileName: String? = nil,
    fileSize: Int? = nil,
    profileImageData: Data?,
    isFavorite: Bool,
    isPinned: Bool = false,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.contactId = contactId
    self.contactName = contactName
    self.content = content
    self.imageData = imageData
    self.voiceMemoData = voiceMemoData
    self.voiceMemoDuration = voiceMemoDuration
    self.voiceMemoWaveform = voiceMemoWaveform
    self.fileData = fileData
    self.fileName = fileName
    self.fileSize = fileSize
    self.profileImageData = profileImageData
    self.isFavorite = isFavorite
    self.isPinned = isPinned
    self.createdAt = createdAt
  }

  convenience init(note: Note) {
    self.init(
      id: note.id,
      contactId: note.contactId,
      contactName: note.contactName,
      content: note.content,
      imageData: note.imageData,
      voiceMemoData: note.voiceMemoData,
      voiceMemoDuration: note.voiceMemoDuration,
      voiceMemoWaveform: note.voiceMemoWaveform,
      fileData: note.fileData,
      fileName: note.fileName,
      fileSize: note.fileSize,
      profileImageData: note.profileImageData,
      isFavorite: note.isFavorite,
      isPinned: note.isPinned,
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
    voiceMemoData = note.voiceMemoData
    voiceMemoDuration = note.voiceMemoDuration
    voiceMemoWaveform = note.voiceMemoWaveform
    fileData = note.fileData
    fileName = note.fileName
    fileSize = note.fileSize
    profileImageData = note.profileImageData
    isFavorite = note.isFavorite
    isPinned = note.isPinned
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
      voiceMemoData: voiceMemoData,
      voiceMemoDuration: voiceMemoDuration,
      voiceMemoWaveform: voiceMemoWaveform,
      fileData: fileData,
      fileName: fileName,
      fileSize: fileSize,
      profileImageData: profileImageData,
      isFavorite: isFavorite,
      isPinned: isPinned
    )
  }
}
