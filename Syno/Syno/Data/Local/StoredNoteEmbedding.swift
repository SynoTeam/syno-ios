import Foundation
import SwiftData

@Model
final class StoredNoteEmbedding {
  var noteId: UUID = UUID()
  var contentFingerprint: String = ""
  var vectorData: Data = Data()
  var updatedAt: Date = Date()

  init(noteId: UUID, contentFingerprint: String, vectorData: Data, updatedAt: Date) {
    self.noteId = noteId
    self.contentFingerprint = contentFingerprint
    self.vectorData = vectorData
    self.updatedAt = updatedAt
  }
}
