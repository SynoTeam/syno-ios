import Foundation
import OSLog
import SwiftData

@ModelActor
actor SwiftDataNoteImageAnalysisRepository: NoteImageAnalysisRepository {
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "NoteImageAnalysisRepository"
  )

  func fetch(noteId: Note.ID) throws -> NoteImageAnalysisResult? {
    let descriptor = FetchDescriptor<StoredNoteImageAnalysis>(
      predicate: #Predicate { $0.noteId == noteId }
    )
    guard let stored = try modelContext.fetch(descriptor).first else {
      return nil
    }
    return NoteImageAnalysisResult(
      labels: stored.labels,
      ocrText: stored.ocrText
    )
  }

  func fetchAll() throws -> [Note.ID: NoteImageAnalysisResult] {
    let storedAnalyses = try modelContext.fetch(
      FetchDescriptor<StoredNoteImageAnalysis>()
    )
    var results: [Note.ID: NoteImageAnalysisResult] = [:]
    for stored in storedAnalyses {
      results[stored.noteId] = NoteImageAnalysisResult(
        labels: stored.labels,
        ocrText: stored.ocrText
      )
    }
    return results
  }

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
