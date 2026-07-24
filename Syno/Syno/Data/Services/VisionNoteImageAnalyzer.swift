import Foundation
import Vision

actor VisionNoteImageAnalyzer: NoteImageAnalyzing {
  private let maximumLabelCount: Int
  private let minimumLabelConfidence: VNConfidence

  init(
    maximumLabelCount: Int = 10,
    minimumLabelConfidence: VNConfidence = 0.05
  ) {
    self.maximumLabelCount = maximumLabelCount
    self.minimumLabelConfidence = minimumLabelConfidence
  }

  func analyze(imageData: Data) async throws -> NoteImageAnalysisResult {
    let classificationRequest = VNClassifyImageRequest()
    let textRequest = VNRecognizeTextRequest()
    textRequest.recognitionLevel = .accurate
    textRequest.usesLanguageCorrection = true
    textRequest.recognitionLanguages = ["ko-KR", "en-US"]

    let handler = VNImageRequestHandler(data: imageData)
    try handler.perform([classificationRequest, textRequest])

    let labels = (classificationRequest.results ?? [])
      .filter { $0.confidence >= minimumLabelConfidence }
      .prefix(maximumLabelCount)
      .map(\.identifier)
    let recognizedLines = (textRequest.results ?? []).compactMap {
      $0.topCandidates(1).first?.string
    }

    return NoteImageAnalysisResult(
      labels: Array(labels),
      ocrText: recognizedLines.joined(separator: "\n")
    )
  }
}
