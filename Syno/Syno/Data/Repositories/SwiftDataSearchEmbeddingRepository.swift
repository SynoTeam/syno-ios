import Foundation
import OSLog
import SwiftData

@ModelActor
actor SwiftDataSearchEmbeddingRepository: SearchEmbeddingRepository {
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "SearchEmbeddingRepository"
  )

  func noteEmbeddings() throws -> [Note.ID: NoteEmbedding] {
    let storedEmbeddings = try modelContext.fetch(FetchDescriptor<StoredNoteEmbedding>())
    return try Dictionary(
      uniqueKeysWithValues: storedEmbeddings.map {
        (
          $0.noteId,
          NoteEmbedding(
            noteId: $0.noteId,
            contentFingerprint: $0.contentFingerprint,
            vector: try decode($0.vectorData),
            updatedAt: $0.updatedAt
          )
        )
      }
    )
  }

  func contactEmbeddings() throws -> [Contact.ID: ContactEmbedding] {
    let storedEmbeddings = try modelContext.fetch(FetchDescriptor<StoredContactEmbedding>())
    return try Dictionary(
      uniqueKeysWithValues: storedEmbeddings.map {
        (
          $0.contactId,
          ContactEmbedding(
            contactId: $0.contactId,
            contentFingerprint: $0.contentFingerprint,
            vector: try decode($0.vectorData),
            updatedAt: $0.updatedAt
          )
        )
      }
    )
  }

  func save(_ embeddings: [NoteEmbedding]) throws {
    guard !embeddings.isEmpty else { return }
    do {
      let storedById = Dictionary(
        uniqueKeysWithValues: try modelContext.fetch(
          FetchDescriptor<StoredNoteEmbedding>()
        ).map { ($0.noteId, $0) }
      )
      for embedding in embeddings {
        let vectorData = try encode(embedding.vector)
        if let stored = storedById[embedding.noteId] {
          stored.contentFingerprint = embedding.contentFingerprint
          stored.vectorData = vectorData
          stored.updatedAt = embedding.updatedAt
        } else {
          modelContext.insert(
            StoredNoteEmbedding(
              noteId: embedding.noteId,
              contentFingerprint: embedding.contentFingerprint,
              vectorData: vectorData,
              updatedAt: embedding.updatedAt
            )
          )
        }
      }
      try modelContext.save()
    } catch {
      modelContext.rollback()
      logger.error("Failed to save note embedding: \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }

  func save(_ embeddings: [ContactEmbedding]) throws {
    guard !embeddings.isEmpty else { return }
    do {
      let storedById = Dictionary(
        uniqueKeysWithValues: try modelContext.fetch(
          FetchDescriptor<StoredContactEmbedding>()
        ).map { ($0.contactId, $0) }
      )
      for embedding in embeddings {
        let vectorData = try encode(embedding.vector)
        if let stored = storedById[embedding.contactId] {
          stored.contentFingerprint = embedding.contentFingerprint
          stored.vectorData = vectorData
          stored.updatedAt = embedding.updatedAt
        } else {
          modelContext.insert(
            StoredContactEmbedding(
              contactId: embedding.contactId,
              contentFingerprint: embedding.contentFingerprint,
              vectorData: vectorData,
              updatedAt: embedding.updatedAt
            )
          )
        }
      }
      try modelContext.save()
    } catch {
      modelContext.rollback()
      logger.error("Failed to save contact embedding: \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }

  func deleteNoteEmbedding(id: Note.ID) throws {
    let descriptor = FetchDescriptor<StoredNoteEmbedding>(
      predicate: #Predicate { $0.noteId == id }
    )
    if let stored = try modelContext.fetch(descriptor).first {
      modelContext.delete(stored)
      try modelContext.save()
    }
  }

  func deleteContactEmbedding(id: Contact.ID) throws {
    let descriptor = FetchDescriptor<StoredContactEmbedding>(
      predicate: #Predicate { $0.contactId == id }
    )
    if let stored = try modelContext.fetch(descriptor).first {
      modelContext.delete(stored)
      try modelContext.save()
    }
  }

  private func encode(_ vector: [Double]) throws -> Data {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    return try encoder.encode(vector)
  }

  private func decode(_ data: Data) throws -> [Double] {
    try PropertyListDecoder().decode([Double].self, from: data)
  }
}
