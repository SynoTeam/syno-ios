import Foundation

/// 이미지 메모에서 추출한 파생 분석 결과입니다.
struct NoteImageAnalysisResult: Equatable, Sendable {
  let labels: [String]
  let ocrText: String

  nonisolated init(labels: [String], ocrText: String) {
    self.labels = labels
    self.ocrText = ocrText
  }
}
