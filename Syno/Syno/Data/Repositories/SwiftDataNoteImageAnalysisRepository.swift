import Foundation
import OSLog
import SwiftData

@ModelActor
actor SwiftDataNoteImageAnalysisRepository: NoteImageAnalysisRepository {
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "NoteImageAnalysisRepository"
  )

  func save(
    noteId: Note.ID,
    result: NoteImageAnalysisResult,
    analyzedAt: Date = Date()
  ) throws {
    do {
      let descriptor = FetchDescriptor<StoredNoteImageAnalysis>(
        predicate: #Predicate { $0.noteId == noteId }
      )
      if let stored = try modelContext.fetch(descriptor).first {
        stored.labels = result.labels
        stored.ocrText = result.ocrText
        stored.analyzedAt = analyzedAt
      } else {
        modelContext.insert(
          StoredNoteImageAnalysis(
            noteId: noteId,
            result: result,
            analyzedAt: analyzedAt
          )
        )
      }
      try modelContext.save()
    } catch {
      modelContext.rollback()
      logger.error(
        "Failed to save image analysis for note \(noteId): \(error.localizedDescription, privacy: .public)"
      )
      throw error
    }
  }
}
