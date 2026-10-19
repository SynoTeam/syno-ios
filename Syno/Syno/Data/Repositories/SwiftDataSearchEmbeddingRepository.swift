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
    let embeddings = try storedEmbeddings.map {
      NoteEmbedding(
        noteId: $0.noteId,
        contentFingerprint: $0.contentFingerprint,
        vector: try decode($0.vectorData),
        updatedAt: $0.updatedAt
      )
    }
    // CloudKit 연동 모델은 유니크 제약을 걸 수 없어 같은 노트의 행이 둘 이상일 수 있습니다. 더 최근 것을 씁니다.
    return Dictionary(
      embeddings.map { ($0.noteId, $0) },
      uniquingKeysWith: { $0.updatedAt >= $1.updatedAt ? $0 : $1 }
    )
  }

  func contactEmbeddings() throws -> [Contact.ID: ContactEmbedding] {
    let storedEmbeddings = try modelContext.fetch(FetchDescriptor<StoredContactEmbedding>())
    let embeddings = try storedEmbeddings.map {
      ContactEmbedding(
        contactId: $0.contactId,
        contentFingerprint: $0.contentFingerprint,
        vector: try decode($0.vectorData),
        updatedAt: $0.updatedAt
      )
    }
    // 같은 연락처의 행이 둘 이상이면 더 최근 것을 씁니다.
    return Dictionary(
      embeddings.map { ($0.contactId, $0) },
      uniquingKeysWith: { $0.updatedAt >= $1.updatedAt ? $0 : $1 }
    )
  }

  func save(_ embeddings: [NoteEmbedding]) throws {
    guard !embeddings.isEmpty else { return }
    do {
      var storedById: [Note.ID: StoredNoteEmbedding] = [:]
      for row in try modelContext.fetch(FetchDescriptor<StoredNoteEmbedding>()) {
        guard let existing = storedById[row.noteId] else {
          storedById[row.noteId] = row
          continue
        }
        // 같은 노트의 행이 둘 이상이면 더 최근 것만 남기고 지웁니다. 검색 캐시라 다시 만들 수 있습니다.
        if row.updatedAt > existing.updatedAt {
          modelContext.delete(existing)
          storedById[row.noteId] = row
        } else {
          modelContext.delete(row)
        }
      }
      for embedding in embeddings {
        let vectorData = try encode(embedding.vector)
        if let stored = storedById[embedding.noteId] {
          stored.contentFingerprint = embedding.contentFingerprint
          stored.vectorData = vectorData
          stored.updatedAt = embedding.updatedAt
        } else {
          let inserted = StoredNoteEmbedding(
            noteId: embedding.noteId,
            contentFingerprint: embedding.contentFingerprint,
            vectorData: vectorData,
            updatedAt: embedding.updatedAt
          )
          modelContext.insert(inserted)
          // 같은 배열에 같은 노트가 또 있어도 다시 삽입하지 않도록 방금 만든 행을 기록합니다.
          storedById[embedding.noteId] = inserted
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
      var storedById: [Contact.ID: StoredContactEmbedding] = [:]
      for row in try modelContext.fetch(FetchDescriptor<StoredContactEmbedding>()) {
        guard let existing = storedById[row.contactId] else {
          storedById[row.contactId] = row
          continue
        }
        // 같은 연락처의 행이 둘 이상이면 더 최근 것만 남기고 지웁니다.
        if row.updatedAt > existing.updatedAt {
          modelContext.delete(existing)
          storedById[row.contactId] = row
        } else {
          modelContext.delete(row)
        }
      }
      for embedding in embeddings {
        let vectorData = try encode(embedding.vector)
        if let stored = storedById[embedding.contactId] {
          stored.contentFingerprint = embedding.contentFingerprint
          stored.vectorData = vectorData
          stored.updatedAt = embedding.updatedAt
        } else {
          let inserted = StoredContactEmbedding(
            contactId: embedding.contactId,
            contentFingerprint: embedding.contentFingerprint,
            vectorData: vectorData,
            updatedAt: embedding.updatedAt
          )
          modelContext.insert(inserted)
          storedById[embedding.contactId] = inserted
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
    // 같은 노트의 행이 중복돼 있을 수 있어 일치하는 행을 모두 지웁니다.
    let rows = try modelContext.fetch(descriptor)
    guard !rows.isEmpty else { return }
    rows.forEach { modelContext.delete($0) }
    try modelContext.save()
  }

  func deleteContactEmbedding(id: Contact.ID) throws {
    let descriptor = FetchDescriptor<StoredContactEmbedding>(
      predicate: #Predicate { $0.contactId == id }
    )
    let rows = try modelContext.fetch(descriptor)
    guard !rows.isEmpty else { return }
    rows.forEach { modelContext.delete($0) }
    try modelContext.save()
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
