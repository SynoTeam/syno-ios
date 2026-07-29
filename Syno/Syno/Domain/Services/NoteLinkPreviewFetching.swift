import Foundation

protocol NoteLinkPreviewFetching: Sendable {
  func fetchPreview(for url: URL) async throws -> NoteLinkPreviewResult
}
