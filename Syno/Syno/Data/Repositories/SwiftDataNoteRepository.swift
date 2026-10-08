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
        let previews = try modelContext.fetch(FetchDescriptor<StoredNoteLinkPreview>())
        for preview in previews where preview.noteId == id {
          modelContext.delete(preview)
        }
        let analyses = try modelContext.fetch(FetchDescriptor<StoredNoteImageAnalysis>())
        for analysis in analyses where analysis.noteId == id {
          modelContext.delete(analysis)
        }
        let transcripts = try modelContext.fetch(FetchDescriptor<StoredNoteVoiceTranscript>())
        for transcript in transcripts where transcript.noteId == id {
          modelContext.delete(transcript)
        }
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

  func deleteAll(contactId: UUID) throws {
    do {
      let descriptor = FetchDescriptor<StoredNote>(
        predicate: #Predicate { $0.contactId == contactId }
      )
      let storedNotes = try modelContext.fetch(descriptor)
      guard !storedNotes.isEmpty else {
        return
      }

      let noteIDs = Set(storedNotes.map(\.id))

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
      for storedNote in storedNotes {
        modelContext.delete(storedNote)
      }

      try modelContext.save()
      if let searchIndex {
        Task {
          for id in noteIDs {
            await searchIndex.remove(SearchDocumentKey(kind: .note, sourceId: id))
          }
        }
      }
    } catch {
      modelContext.rollback()
      logger.error("Failed to delete notes for contact \(contactId): \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }
}
