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
        modelContext.delete(storedNote)
        try modelContext.save()
        if let searchIndex {
          let key = SearchDocumentKey(kind: .note, sourceId: id)
          Task { await searchIndex.remove(key) }
        }
      }
    } catch {
      modelContext.rollback()
      logger.error("Failed to delete note \(id): \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }
}
