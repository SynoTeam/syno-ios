import Foundation
import SwiftData

/// 원본 노트와 분리해 저장하는 URL 링크 미리보기 캐시입니다.
@Model
final class StoredNoteLinkPreview {
  var noteId: UUID = UUID()
  var title: String = ""
  var imageURLString: String?
  var siteURLString: String = ""
  var fetchedAt: Date = Date()

  init(noteId: UUID, result: NoteLinkPreviewResult, fetchedAt: Date = Date()) {
    self.noteId = noteId
    title = result.title
    imageURLString = result.imageURL?.absoluteString
    siteURLString = result.siteURL.absoluteString
    self.fetchedAt = fetchedAt
  }
}
