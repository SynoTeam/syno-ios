import Foundation

/// 링크 미리보기 결과와 저장 모델 사이의 변환입니다. 앱 타깃에만 둡니다.
extension StoredNoteLinkPreview {
  convenience init(noteId: UUID, result: NoteLinkPreviewResult, fetchedAt: Date = Date()) {
    self.init(
      noteId: noteId,
      title: result.title,
      imageURLString: result.imageURL?.absoluteString,
      siteURLString: result.siteURL.absoluteString,
      fetchedAt: fetchedAt
    )
  }
}
