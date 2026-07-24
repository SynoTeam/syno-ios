protocol TextEmbeddingProviding: Sendable {
  func embedding(for text: String) async throws -> [Double]
}

@MainActor
protocol SearchIndexing {
  func index(_ document: SearchDocument) async
  func backfill(_ documents: [SearchDocument], batchSize: Int) async
  func remove(_ key: SearchDocumentKey) async
  func scores(
    for query: String,
    documents: [SearchDocument]
  ) async -> [SearchDocumentKey: Double]
}
