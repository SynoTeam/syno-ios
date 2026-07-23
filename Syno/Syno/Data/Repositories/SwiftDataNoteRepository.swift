import Foundation
import OSLog
import SwiftData

@MainActor
final class SwiftDataNoteRepository: NoteRepository {
  private let modelContext: ModelContext
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "NoteRepository"
  )

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
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
      }
    } catch {
      modelContext.rollback()
      logger.error("Failed to delete note \(id): \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }
}
