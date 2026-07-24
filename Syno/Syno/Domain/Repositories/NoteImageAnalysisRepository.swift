import Foundation

protocol NoteImageAnalysisRepository: Sendable {
  func save(
    noteId: Note.ID,
    result: NoteImageAnalysisResult,
    analyzedAt: Date
  ) async throws
}
