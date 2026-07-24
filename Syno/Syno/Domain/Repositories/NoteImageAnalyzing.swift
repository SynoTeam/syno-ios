import Foundation

protocol NoteImageAnalyzing: Sendable {
  func analyze(imageData: Data) async throws -> NoteImageAnalysisResult
}
