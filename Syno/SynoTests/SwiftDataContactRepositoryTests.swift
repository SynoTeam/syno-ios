import SwiftData
import XCTest
@testable import Syno

final class SwiftDataContactRepositoryTests: XCTestCase {
  @MainActor
  func testDeleteRemovesVoiceTranscriptsOfDeletedContactNotes() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    let contactRepository = SwiftDataContactRepository(modelContext: context)
    let noteRepository = SwiftDataNoteRepository(modelContext: context)
    let deletedContact = Contact(name: "삭제 대상", role: "", company: "")
    let keptContact = Contact(name: "유지 대상", role: "", company: "")
    try contactRepository.save(deletedContact)
    try contactRepository.save(keptContact)

    let deletedNote = Note(contactId: deletedContact.id, contactName: deletedContact.name, content: "음성")
    let keptNote = Note(contactId: keptContact.id, contactName: keptContact.name, content: "음성")
    try noteRepository.save(deletedNote)
    try noteRepository.save(keptNote)
    context.insert(StoredNoteVoiceTranscript(noteId: deletedNote.id, text: "삭제될 전사"))
    context.insert(StoredNoteVoiceTranscript(noteId: keptNote.id, text: "남을 전사"))
    try context.save()

    try contactRepository.delete(id: deletedContact.id)

    let transcripts = try context.fetch(FetchDescriptor<StoredNoteVoiceTranscript>())
    XCTAssertEqual(transcripts.map(\.noteId), [keptNote.id])
  }

  @MainActor
  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: StoredContact.self,
      StoredNote.self,
      StoredNoteLinkPreview.self,
      StoredNoteImageAnalysis.self,
      StoredNoteVoiceTranscript.self,
      StoredNoteEmbedding.self,
      StoredContactEmbedding.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
  }
}
