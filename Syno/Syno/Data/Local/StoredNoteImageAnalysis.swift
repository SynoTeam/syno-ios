import Foundation
import SwiftData

/// 원본 메모와 분리해 저장하는 이미지 분석 파생 데이터입니다.
@Model
final class StoredNoteImageAnalysis {
  @Attribute(.unique) var noteId: UUID
  var labels: [String]
  var ocrText: String
  var analyzedAt: Date

  init(
    noteId: UUID,
    labels: [String],
    ocrText: String,
    analyzedAt: Date = Date()
  ) {
    self.noteId = noteId
    self.labels = labels
    self.ocrText = ocrText
    self.analyzedAt = analyzedAt
  }

  convenience init(
    noteId: UUID,
    result: NoteImageAnalysisResult,
    analyzedAt: Date = Date()
  ) {
    self.init(
      noteId: noteId,
      labels: result.labels,
      ocrText: result.ocrText,
      analyzedAt: analyzedAt
    )
  }
}
