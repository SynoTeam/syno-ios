import Foundation
import SwiftData

@Model
final class StoredContactEmbedding {
  @Attribute(.unique) var contactId: UUID
  var contentFingerprint: String
  var vectorData: Data
  var updatedAt: Date

  init(contactId: UUID, contentFingerprint: String, vectorData: Data, updatedAt: Date) {
    self.contactId = contactId
    self.contentFingerprint = contentFingerprint
    self.vectorData = vectorData
    self.updatedAt = updatedAt
  }
}
