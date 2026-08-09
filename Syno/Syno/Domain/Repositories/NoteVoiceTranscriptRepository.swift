import Foundation

protocol NoteVoiceTranscriptRepository: Sendable {
  func fetch(noteId: Note.ID) async throws -> NoteVoiceTranscriptResult?
  func fetchAll() async throws -> [Note.ID: NoteVoiceTranscriptResult]
  func save(noteId: Note.ID, result: NoteVoiceTranscriptResult, transcribedAt: Date) async throws
}
