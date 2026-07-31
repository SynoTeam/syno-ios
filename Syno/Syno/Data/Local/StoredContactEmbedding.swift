import Foundation
import SwiftData

@Model
final class StoredContactEmbedding {
  var contactId: UUID = UUID()
  var contentFingerprint: String = ""
  var vectorData: Data = Data()
  var updatedAt: Date = Date()

  init(contactId: UUID, contentFingerprint: String, vectorData: Data, updatedAt: Date) {
    self.contactId = contactId
    self.contentFingerprint = contentFingerprint
    self.vectorData = vectorData
    self.updatedAt = updatedAt
  }
}
