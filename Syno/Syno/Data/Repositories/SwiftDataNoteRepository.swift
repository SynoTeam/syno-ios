import Foundation
import OSLog
import SwiftData

@MainActor
final class SwiftDataNoteRepository: NoteRepository {
  private let modelContext: ModelContext
  private let searchIndex: (any SearchIndexing)?
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "NoteRepository"
  )

  init(
    modelContext: ModelContext,
    searchIndex: (any SearchIndexing)? = nil
  ) {
    self.modelContext = modelContext
    self.searchIndex = searchIndex
  }

  func fetch(contactId: UUID?) throws -> [Note] {
    do {
      let descriptor = FetchDescriptor<StoredNote>(
        predicate: #Predicate { $0.contactId == contactId },
        sortBy: [SortDescriptor(\.createdAt)]
      )
      return try modelContext.fetch(descriptor).map(\.note)
    } catch {
      logger.error("Failed to fetch notes: \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }

  func save(_ note: Note) throws {
    do {
      let id = note.id
      let descriptor = FetchDescriptor<StoredNote>(
        predicate: #Predicate { $0.id == id }
      )

      if let storedNote = try modelContext.fetch(descriptor).first {
        storedNote.update(with: note)
      } else {
        modelContext.insert(StoredNote(note: note))
      }

      try modelContext.save()
      if let searchIndex {
        let document = SearchDocument.note(
          id: note.id,
          text: note.content
        )
        Task { await searchIndex.index(document) }
      }
    } catch {
      modelContext.rollback()
      logger.error("Failed to save note \(note.id): \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }

  func delete(id: Note.ID) throws {
    do {
      let descriptor = FetchDescriptor<StoredNote>(
        predicate: #Predicate { $0.id == id }
      )
      if let storedNote = try modelContext.fetch(descriptor).first {
        try deleteRelatedData(forNoteIDs: [id])
        modelContext.delete(storedNote)
        try modelContext.save()
        removeFromSearchIndex(noteIDs: [id])
      }
    } catch {
      modelContext.rollback()
      logger.error("Failed to delete note \(id): \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }

  func deleteAll(contactIds: [UUID]) throws {
    do {
      var storedNotes: [StoredNote] = []
      for contactId in Set(contactIds) {
        let descriptor = FetchDescriptor<StoredNote>(
          predicate: #Predicate { $0.contactId == contactId }
        )
        storedNotes.append(contentsOf: try modelContext.fetch(descriptor))
      }
      guard !storedNotes.isEmpty else {
        return
      }

      let noteIDs = Set(storedNotes.map(\.id))
      try deleteRelatedData(forNoteIDs: noteIDs)
      for storedNote in storedNotes {
        modelContext.delete(storedNote)
      }

      // 여러 연락처를 한 번에 지워도 저장은 한 번이라 중간에 실패하면 모두 롤백된다.
      try modelContext.save()
      removeFromSearchIndex(noteIDs: noteIDs)
    } catch {
      modelContext.rollback()
      logger.error("Failed to delete notes for contacts: \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }

  /// 노트에 연결된 링크 프리뷰, 이미지 분석, 음성 전사, 검색 임베딩을 같은 트랜잭션에서 삭제합니다.
  private func deleteRelatedData(forNoteIDs noteIDs: Set<Note.ID>) throws {
    let previews = try modelContext.fetch(FetchDescriptor<StoredNoteLinkPreview>())
    for preview in previews where noteIDs.contains(preview.noteId) {
      modelContext.delete(preview)
    }
    let analyses = try modelContext.fetch(FetchDescriptor<StoredNoteImageAnalysis>())
    for analysis in analyses where noteIDs.contains(analysis.noteId) {
      modelContext.delete(analysis)
    }
    let transcripts = try modelContext.fetch(FetchDescriptor<StoredNoteVoiceTranscript>())
    for transcript in transcripts where noteIDs.contains(transcript.noteId) {
      modelContext.delete(transcript)
    }
    let embeddings = try modelContext.fetch(FetchDescriptor<StoredNoteEmbedding>())
    for embedding in embeddings where noteIDs.contains(embedding.noteId) {
      modelContext.delete(embedding)
    }
  }

  private func removeFromSearchIndex(noteIDs: Set<Note.ID>) {
    guard let searchIndex else {
      return
    }
    Task {
      for id in noteIDs {
        await searchIndex.remove(SearchDocumentKey(kind: .note, sourceId: id))
      }
    }
  }
}
