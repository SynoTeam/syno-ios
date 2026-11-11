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

  /// 여러 장을 한 번에 보낸 사진의 묶음 식별자입니다.
  var photoGroupId: UUID?

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
    createdAt: Date = Date(),
    photoGroupId: UUID? = nil
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
    self.photoGroupId = photoGroupId
  }
}
