import Foundation

/// 앱의 `Note`와 저장 모델 사이의 변환입니다.
/// 공유 확장은 Domain 타입을 모르므로 이 파일은 앱 타깃에만 둡니다.
extension StoredNote {
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
      createdAt: note.createdAt,
      photoGroupId: note.photoGroupId
    )
  }

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
    photoGroupId = note.photoGroupId
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
      isPinned: isPinned,
      photoGroupId: photoGroupId
    )
  }
}
