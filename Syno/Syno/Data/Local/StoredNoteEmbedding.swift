import Foundation
import SwiftData

@Model
final class StoredNoteEmbedding {
  @Attribute(.unique) var noteId: UUID
  var contentFingerprint: String
  var vectorData: Data
  var updatedAt: Date

  init(noteId: UUID, contentFingerprint: String, vectorData: Data, updatedAt: Date) {
    self.noteId = noteId
    self.contentFingerprint = contentFingerprint
    self.vectorData = vectorData
    self.updatedAt = updatedAt
  }
}
