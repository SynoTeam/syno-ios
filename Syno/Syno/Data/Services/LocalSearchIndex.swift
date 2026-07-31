import CryptoKit
import Foundation
import OSLog

@MainActor
final class LocalSearchIndex: SearchIndexing {
  private let repository: any SearchEmbeddingRepository
  private let embeddingProvider: any TextEmbeddingProviding
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "LocalSearchIndex"
  )

  init(
    repository: any SearchEmbeddingRepository,
    embeddingProvider: any TextEmbeddingProviding
  ) {
    self.repository = repository
    self.embeddingProvider = embeddingProvider
  }

  func index(_ document: SearchDocument) async {
    await backfill([document], batchSize: 1)
  }

  func backfill(_ documents: [SearchDocument], batchSize: Int = 20) async {
    let eligibleDocuments = documents.filter(\.isSemanticEligible)
    guard !eligibleDocuments.isEmpty else { return }
    do {
      var noteCache = try await repository.noteEmbeddings()
      var contactCache = try await repository.contactEmbeddings()
      let size = max(1, batchSize)

      for start in stride(from: 0, to: eligibleDocuments.count, by: size) {
        guard !Task.isCancelled else { return }
        let end = min(start + size, eligibleDocuments.count)
        let additions = await createMissingEmbeddings(
          for: Array(eligibleDocuments[start..<end]),
          noteCache: noteCache,
          contactCache: contactCache
        )
        try await repository.save(additions.notes)
        try await repository.save(additions.contacts)
        additions.notes.forEach { noteCache[$0.noteId] = $0 }
        additions.contacts.forEach { contactCache[$0.contactId] = $0 }
        await Task.yield()
      }
    } catch {
      logger.notice(
        "Skipping embedding backfill: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  func remove(_ key: SearchDocumentKey) async {
    do {
      switch key.kind {
      case .note:
        try await repository.deleteNoteEmbedding(id: key.sourceId)
      case .contact:
        try await repository.deleteContactEmbedding(id: key.sourceId)
      }
    } catch {
      logger.error(
        "Failed to remove embedding cache for \(key.sourceId): \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  func scores(
    for query: String,
    documents: [SearchDocument]
  ) async -> [SearchDocumentKey: Double] {
    guard !documents.isEmpty else { return [:] }
    let eligibleDocuments = documents.filter(\.isSemanticEligible)
    guard !eligibleDocuments.isEmpty else {
      logger.debug(
        "Query embedding skipped; all documents use short-text bi-gram fallback query=\(query, privacy: .public)"
      )
      return fallbackScores(for: query, documents: documents)
    }

    let queryEmbedding: [Double]
    do {
      queryEmbedding = try await embeddingProvider.embedding(for: query)
      logger.debug(
        "Query embedding succeeded query=\(query, privacy: .public) dimensions=\(queryEmbedding.count)"
      )
    } catch {
      logger.debug(
        "Query embedding failed; using bi-gram fallback query=\(query, privacy: .public) error=\(String(describing: error), privacy: .public)"
      )
      return fallbackScores(for: query, documents: documents)
    }

    do {
      let noteCache = try await repository.noteEmbeddings()
      let contactCache = try await repository.contactEmbeddings()
      let additions = await createMissingEmbeddings(
        for: eligibleDocuments,
        noteCache: noteCache,
        contactCache: contactCache
      )
      try await repository.save(additions.notes)
      try await repository.save(additions.contacts)

      let addedNoteVectors = additions.notes.reduce(into: [Note.ID: [Double]]()) {
        $0[$1.noteId] = $1.vector
      }
      let addedContactVectors = additions.contacts.reduce(into: [Contact.ID: [Double]]()) {
        $0[$1.contactId] = $1.vector
      }
      return Dictionary(uniqueKeysWithValues: documents.map { document in
        let vector: [Double]?
        if !document.isSemanticEligible {
          vector = nil
        } else {
          switch document.key.kind {
          case .note:
            let cached = noteCache[document.key.sourceId]
            vector = addedNoteVectors[document.key.sourceId]
              ?? (cached?.contentFingerprint == contentFingerprint(document.text)
                ? cached?.vector : nil)
          case .contact:
            let cached = contactCache[document.key.sourceId]
            vector = addedContactVectors[document.key.sourceId]
              ?? (cached?.contentFingerprint == contentFingerprint(document.text)
                ? cached?.vector : nil)
          }
        }
        let score: Double
        if let vector {
          let rawCosine = cosineSimilarity(queryEmbedding, vector)
          score = normalizedSemanticScore(rawCosine)
          logScore(
            document: document,
            rawCosine: rawCosine,
            normalizedScore: score,
            fallbackScore: nil,
            path: "semantic"
          )
        } else {
          score = characterNGramSimilarity(query, document.text)
          logScore(
            document: document,
            rawCosine: nil,
            normalizedScore: nil,
            fallbackScore: score,
            path: "bi-gram"
          )
        }
        return (document.key, score)
      })
    } catch {
      logger.debug(
        "Semantic scoring pipeline failed; using bi-gram fallback query=\(query, privacy: .public) error=\(String(describing: error), privacy: .public)"
      )
      return fallbackScores(for: query, documents: documents)
    }
  }

  private func createMissingEmbeddings(
    for documents: [SearchDocument],
    noteCache: [Note.ID: NoteEmbedding],
    contactCache: [Contact.ID: ContactEmbedding]
  ) async -> (notes: [NoteEmbedding], contacts: [ContactEmbedding]) {
    var notes: [NoteEmbedding] = []
    var contacts: [ContactEmbedding] = []

    for document in documents {
      guard !Task.isCancelled else { break }
      guard document.isSemanticEligible else { continue }
      let fingerprint = contentFingerprint(document.text)
      let isCurrent: Bool
      switch document.key.kind {
      case .note:
        isCurrent = noteCache[document.key.sourceId]?.contentFingerprint == fingerprint
      case .contact:
        isCurrent = contactCache[document.key.sourceId]?.contentFingerprint == fingerprint
      }
      guard !isCurrent else { continue }

      do {
        let vector = try await embeddingProvider.embedding(for: document.text)
        switch document.key.kind {
        case .note:
          notes.append(
            NoteEmbedding(
              noteId: document.key.sourceId,
              contentFingerprint: fingerprint,
              vector: vector,
              updatedAt: Date()
            )
          )
        case .contact:
          contacts.append(
            ContactEmbedding(
              contactId: document.key.sourceId,
              contentFingerprint: fingerprint,
              vector: vector,
              updatedAt: Date()
            )
          )
        }
      } catch {
        logger.notice(
          "Skipping embedding cache for \(document.key.sourceId): \(error.localizedDescription, privacy: .public)"
        )
      }
    }
    return (notes, contacts)
  }

  private func fallbackScores(
    for query: String,
    documents: [SearchDocument]
  ) -> [SearchDocumentKey: Double] {
    Dictionary(
      uniqueKeysWithValues: documents.map { document in
        let score = characterNGramSimilarity(query, document.text)
        logScore(
          document: document,
          rawCosine: nil,
          normalizedScore: nil,
          fallbackScore: score,
          path: "bi-gram"
        )
        return (document.key, score)
      }
    )
  }

  private func logScore(
    document: SearchDocument,
    rawCosine: Double?,
    normalizedScore: Double?,
    fallbackScore: Double?,
    path: String
  ) {
    let rawCosineText = rawCosine.map { String(format: "%.6f", $0) } ?? "n/a"
    let normalizedText = normalizedScore.map { String(format: "%.6f", $0) } ?? "n/a"
    let fallbackText = fallbackScore.map { String(format: "%.6f", $0) } ?? "n/a"
    logger.debug(
      "Search score sourceId=\(document.key.sourceId.uuidString, privacy: .public) text=\(document.text, privacy: .public) rawCosine=\(rawCosineText, privacy: .public) normalizedSemanticScore=\(normalizedText, privacy: .public) biGramScore=\(fallbackText, privacy: .public) path=\(path, privacy: .public)"
    )
  }

  private func contentFingerprint(_ text: String) -> String {
    SHA256.hash(data: Data(text.utf8))
      .map { String(format: "%02x", $0) }
      .joined()
  }

  private func cosineSimilarity(_ lhs: [Double], _ rhs: [Double]) -> Double {
    guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }
    let dotProduct = zip(lhs, rhs).reduce(0) { $0 + ($1.0 * $1.1) }
    let lhsMagnitude = sqrt(lhs.reduce(0) { $0 + ($1 * $1) })
    let rhsMagnitude = sqrt(rhs.reduce(0) { $0 + ($1 * $1) })
    guard lhsMagnitude > 0, rhsMagnitude > 0 else { return 0 }
    return max(0, min(1, dotProduct / (lhsMagnitude * rhsMagnitude)))
  }

  private func normalizedSemanticScore(_ cosineSimilarity: Double) -> Double {
    max(0, min(1, (cosineSimilarity - 0.6) / 0.4))
  }

  private func characterNGramSimilarity(
    _ lhs: String,
    _ rhs: String,
    size: Int = 2
  ) -> Double {
    let lhsNGrams = characterNGrams(lhs, size: size)
    let rhsNGrams = characterNGrams(rhs, size: size)
    guard !lhsNGrams.isEmpty || !rhsNGrams.isEmpty else { return 1 }
    return Double(lhsNGrams.intersection(rhsNGrams).count)
      / Double(lhsNGrams.union(rhsNGrams).count)
  }

  private func characterNGrams(_ text: String, size: Int) -> Set<String> {
    let characters = Array(text.lowercased().filter { !$0.isWhitespace })
    guard characters.count >= size else {
      return characters.isEmpty ? [] : [String(characters)]
    }
    return Set(
      (0...(characters.count - size)).map {
        String(characters[$0..<($0 + size)])
      }
    )
  }
}
