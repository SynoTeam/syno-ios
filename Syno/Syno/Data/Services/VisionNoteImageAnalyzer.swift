import Foundation
import OSLog
import Vision

actor VisionNoteImageAnalyzer: NoteImageAnalyzing {
  private let maximumLabelCount: Int
  private let minimumLabelConfidence: VNConfidence
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "VisionNoteImageAnalyzer"
  )

  init(
    maximumLabelCount: Int = 10,
    minimumLabelConfidence: VNConfidence = 0.05
  ) {
    self.maximumLabelCount = maximumLabelCount
    self.minimumLabelConfidence = minimumLabelConfidence
  }

  func analyze(imageData: Data) async throws -> NoteImageAnalysisResult {
    let startedAt = Date()
    let classificationRequest = VNClassifyImageRequest()
    var labels: [String] = []
    do {
      let classificationHandler = VNImageRequestHandler(data: imageData)
      try classificationHandler.perform([classificationRequest])
      labels = (classificationRequest.results ?? [])
        .filter { $0.confidence >= minimumLabelConfidence }
        .prefix(maximumLabelCount)
        .map(\.identifier)
    } catch {
      logger.debug(
        "Vision classification unavailable error=\(String(describing: error), privacy: .public)"
      )
    }

    let textRequest = VNRecognizeTextRequest()
    textRequest.recognitionLevel = .accurate
    textRequest.usesLanguageCorrection = true
    textRequest.recognitionLanguages = ["ko-KR", "en-US"]
    var recognizedLines: [String] = []
    do {
      let textHandler = VNImageRequestHandler(data: imageData)
      try textHandler.perform([textRequest])
      recognizedLines = (textRequest.results ?? []).compactMap {
        $0.topCandidates(1).first?.string
      }
    } catch {
      logger.debug(
        "Vision OCR unavailable error=\(String(describing: error), privacy: .public)"
      )
    }

    let result = NoteImageAnalysisResult(
      labels: labels,
      ocrText: recognizedLines.joined(separator: "\n")
    )
    let durationMilliseconds = Int(
      Date().timeIntervalSince(startedAt) * 1_000
    )
    logger.debug(
      "Vision analysis completed durationMs=\(durationMilliseconds) imageBytes=\(imageData.count) labels=\(result.labels.joined(separator: ", "), privacy: .public) ocrText=\(result.ocrText, privacy: .public)"
    )
    return result
  }
}
