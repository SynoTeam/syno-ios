import Foundation

struct ContactEmbedding: Equatable, Sendable {
  let contactId: UUID
  let contentFingerprint: String
  let vector: [Double]
  let updatedAt: Date
}
