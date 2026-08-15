import Foundation
import OSLog
import SwiftData

@ModelActor
actor SwiftDataNoteVoiceTranscriptRepository: NoteVoiceTranscriptRepository {
  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Syno", category: "NoteVoiceTranscriptRepository")

  func fetch(noteId: Note.ID) throws -> NoteVoiceTranscriptResult? {
    let descriptor = FetchDescriptor<StoredNoteVoiceTranscript>(predicate: #Predicate { $0.noteId == noteId })
    return try modelContext.fetch(descriptor).first.map { NoteVoiceTranscriptResult(text: $0.text) }
  }

  func fetchAll() throws -> [Note.ID: NoteVoiceTranscriptResult] {
    Dictionary(uniqueKeysWithValues: try modelContext.fetch(FetchDescriptor<StoredNoteVoiceTranscript>()).map { ($0.noteId, NoteVoiceTranscriptResult(text: $0.text)) })
  }

  func save(noteId: Note.ID, result: NoteVoiceTranscriptResult, transcribedAt: Date) throws {
    do {
      let descriptor = FetchDescriptor<StoredNoteVoiceTranscript>(predicate: #Predicate { $0.noteId == noteId })
      if let stored = try modelContext.fetch(descriptor).first {
        stored.text = result.text
        stored.transcribedAt = transcribedAt
      } else {
        modelContext.insert(StoredNoteVoiceTranscript(noteId: noteId, text: result.text, transcribedAt: transcribedAt))
      }
      try modelContext.save()
    } catch {
      modelContext.rollback()
      logger.error("Failed to save voice transcript for note \(noteId): \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }
}
