import Foundation

struct NoopNoteLinkPreviewFetcher: NoteLinkPreviewFetching {
  func fetchPreview(for url: URL) async throws -> NoteLinkPreviewResult {
    throw URLError(.unsupportedURL)
  }
}

actor NoopNoteLinkPreviewRepository: NoteLinkPreviewRepository {
  func fetch(noteId: Note.ID) throws -> NoteLinkPreviewResult? { nil }
  func fetchAll() throws -> [Note.ID: NoteLinkPreviewResult] { [:] }
  func save(noteId: Note.ID, result: NoteLinkPreviewResult, fetchedAt: Date) throws {}
}
