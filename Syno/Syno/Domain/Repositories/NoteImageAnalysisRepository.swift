import Foundation

protocol NoteImageAnalysisRepository: Sendable {
  func fetch(noteId: Note.ID) async throws -> NoteImageAnalysisResult?
  func fetchAll() async throws -> [Note.ID: NoteImageAnalysisResult]
  func save(
    noteId: Note.ID,
    result: NoteImageAnalysisResult,
    analyzedAt: Date
  ) async throws
}
