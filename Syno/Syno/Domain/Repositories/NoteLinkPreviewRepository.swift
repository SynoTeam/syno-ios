import Foundation

protocol NoteLinkPreviewRepository: Sendable {
  func fetch(noteId: Note.ID) async throws -> NoteLinkPreviewResult?
  func fetchAll() async throws -> [Note.ID: NoteLinkPreviewResult]
  func save(noteId: Note.ID, result: NoteLinkPreviewResult, fetchedAt: Date) async throws
}
