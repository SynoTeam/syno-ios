import SwiftData
import XCTest
@testable import Syno

final class LocalSearchIndexTests: XCTestCase {
  @MainActor
  func testIndexDoesNotRecalculateUnchangedContent() async throws {
    let container = try makeContainer()
    let repository = SwiftDataSearchEmbeddingRepository(
      modelContainer: container
    )
    let provider = CountingEmbeddingProvider()
    let index = LocalSearchIndex(
      repository: repository,
      embeddingProvider: provider
    )
    let noteId = UUID()
    let document = SearchDocument.note(id: noteId, text: "내일 민수와 회의")

    await index.index(document)
    await index.index(document)

    let callCount = await provider.callCount
    XCTAssertEqual(callCount, 1)
    let embeddings = try await repository.noteEmbeddings()
    XCTAssertNotNil(embeddings[noteId])
  }

  @MainActor
  func testIndexRecalculatesWhenContentChanges() async throws {
    let container = try makeContainer()
    let repository = SwiftDataSearchEmbeddingRepository(
      modelContainer: container
    )
    let provider = CountingEmbeddingProvider()
    let index = LocalSearchIndex(
      repository: repository,
      embeddingProvider: provider
    )
    let noteId = UUID()

    await index.index(.note(id: noteId, text: "기존 내용"))
    await index.index(.note(id: noteId, text: "변경된 내용"))

    let callCount = await provider.callCount
    XCTAssertEqual(callCount, 2)
  }

  @MainActor
  func testScoresFallBackToCharacterNGramWhenEmbeddingFails() async throws {
    let container = try makeContainer()
    let repository = SwiftDataSearchEmbeddingRepository(
      modelContainer: container
    )
    let index = LocalSearchIndex(
      repository: repository,
      embeddingProvider: FailingEmbeddingProvider()
    )
    let related = SearchDocument.note(id: UUID(), text: "민수와 내일 회의")
    let unrelated = SearchDocument.note(id: UUID(), text: "주말 파스타 요리")

    let scores = await index.scores(
      for: "민수 회의",
      documents: [related, unrelated]
    )

    XCTAssertGreaterThan(scores[related.key, default: 0], scores[unrelated.key, default: 0])
    let embeddings = try await repository.noteEmbeddings()
    XCTAssertNil(embeddings[related.key.sourceId])
  }

  @MainActor
  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: StoredNoteEmbedding.self,
      StoredContactEmbedding.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
  }
}

private actor CountingEmbeddingProvider: TextEmbeddingProviding {
  private(set) var callCount = 0

  func embedding(for text: String) async throws -> [Double] {
    callCount += 1
    return [Double(text.utf8.count), 1]
  }
}

private struct FailingEmbeddingProvider: TextEmbeddingProviding {
  func embedding(for text: String) async throws -> [Double] {
    throw TextEmbeddingError.assetsUnavailable
  }
}
