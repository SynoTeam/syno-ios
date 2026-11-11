import Foundation

/// 이미지 분석 결과와 저장 모델 사이의 변환입니다. 앱 타깃에만 둡니다.
extension StoredNoteImageAnalysis {
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
