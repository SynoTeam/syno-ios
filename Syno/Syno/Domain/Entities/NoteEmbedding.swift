import Foundation

struct NoteEmbedding: Equatable, Sendable {
  let noteId: UUID
  let contentFingerprint: String
  let vector: [Double]
  let updatedAt: Date
}
