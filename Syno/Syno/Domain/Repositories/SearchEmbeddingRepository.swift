protocol SearchEmbeddingRepository: Sendable {
  func noteEmbeddings() async throws -> [Note.ID: NoteEmbedding]
  func contactEmbeddings() async throws -> [Contact.ID: ContactEmbedding]
  func save(_ embeddings: [NoteEmbedding]) async throws
  func save(_ embeddings: [ContactEmbedding]) async throws
  func deleteNoteEmbedding(id: Note.ID) async throws
  func deleteContactEmbedding(id: Contact.ID) async throws
}
