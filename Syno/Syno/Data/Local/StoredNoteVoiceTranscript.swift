import Foundation
import SwiftData

@Model
final class StoredNoteVoiceTranscript {
  var noteId: UUID = UUID()
  var text: String = ""
  var transcribedAt: Date = Date()

  init(noteId: UUID, text: String, transcribedAt: Date = Date()) {
    self.noteId = noteId
    self.text = text
    self.transcribedAt = transcribedAt
  }
}
