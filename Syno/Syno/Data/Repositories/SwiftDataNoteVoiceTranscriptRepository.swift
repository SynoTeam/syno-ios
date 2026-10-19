import Foundation
import OSLog
import SwiftData

@ModelActor
actor SwiftDataNoteVoiceTranscriptRepository: NoteVoiceTranscriptRepository {
  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Syno", category: "NoteVoiceTranscriptRepository")

  func fetch(noteId: Note.ID) throws -> NoteVoiceTranscriptResult? {
    // 같은 노트의 전사가 중복돼 있으면 `fetchAll()`과 같게 가장 최근 것을 돌려줍니다.
    let descriptor = FetchDescriptor<StoredNoteVoiceTranscript>(
      predicate: #Predicate { $0.noteId == noteId },
      sortBy: [SortDescriptor(\.transcribedAt, order: .reverse)]
    )
    return try modelContext.fetch(descriptor).first.map { NoteVoiceTranscriptResult(text: $0.text) }
  }

  func fetchAll() throws -> [Note.ID: NoteVoiceTranscriptResult] {
    let stored = try modelContext.fetch(FetchDescriptor<StoredNoteVoiceTranscript>())
    // CloudKit 연동 모델은 유니크 제약을 걸 수 없어 같은 노트의 전사가 둘 이상일 수 있습니다. 더 최근 것을 씁니다.
    let newestByNoteId = Dictionary(
      stored.map { ($0.noteId, $0) },
      uniquingKeysWith: { $0.transcribedAt >= $1.transcribedAt ? $0 : $1 }
    )
    return newestByNoteId.mapValues { NoteVoiceTranscriptResult(text: $0.text) }
  }

  func save(noteId: Note.ID, result: NoteVoiceTranscriptResult, transcribedAt: Date) throws {
    do {
      let descriptor = FetchDescriptor<StoredNoteVoiceTranscript>(
        predicate: #Predicate { $0.noteId == noteId },
        sortBy: [SortDescriptor(\.transcribedAt, order: .reverse)]
      )
      let existing = try modelContext.fetch(descriptor)
      if let stored = existing.first {
        stored.text = result.text
        stored.transcribedAt = transcribedAt
        // 중복으로 남아 있던 이전 전사는 지웁니다.
        existing.dropFirst().forEach { modelContext.delete($0) }
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
