import Foundation

@MainActor
protocol NoteRepository {
  func fetch(contactId: UUID?) throws -> [Note]
  func save(_ note: Note) throws
  func delete(id: Note.ID) throws
}
