import Foundation

protocol NoteVoiceTranscribing: Sendable {
  func transcribe(audioData: Data) async throws -> NoteVoiceTranscriptResult
}
