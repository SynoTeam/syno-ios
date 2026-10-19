import SwiftData
import XCTest
@testable import Syno

final class SwiftDataNoteRepositoryTests: XCTestCase {
  @MainActor
  func testFetchReturnsOnlyNotesForRequestedContact() async throws {
    let container = try makeContainer()
    let repository = SwiftDataNoteRepository(modelContext: container.mainContext)
    let requestedContactId = UUID()
    let otherContactId = UUID()

    try repository.save(
      Note(
        contactId: requestedContactId,
        contactName: "검색 대상",
        content: "첫 번째",
        createdAt: Date(timeIntervalSince1970: 100)
      )
    )
    try repository.save(
      Note(
        contactId: otherContactId,
        contactName: "다른 연락처",
        content: "제외 대상",
        createdAt: Date(timeIntervalSince1970: 150)
      )
    )
    try repository.save(
      Note(
        contactId: requestedContactId,
        contactName: "검색 대상",
        content: "두 번째",
        createdAt: Date(timeIntervalSince1970: 200)
      )
    )

    let notes = try repository.fetch(contactId: requestedContactId)

    XCTAssertEqual(notes.map(\.content), ["첫 번째", "두 번째"])
    XCTAssertTrue(notes.allSatisfy { $0.contactId == requestedContactId })
  }

  @MainActor
  func testFetchAllReturnsNotesRegardlessOfContactNewestFirst() async throws {
    let container = try makeContainer()
    let repository = SwiftDataNoteRepository(modelContext: container.mainContext)
    let contactId = UUID()

    try repository.save(
      Note(contactId: contactId, contactName: "연결됨", content: "가장 오래됨", createdAt: Date(timeIntervalSince1970: 100))
    )
    try repository.save(
      Note(contactId: nil, contactName: "연결 안 됨", content: "가장 최신", createdAt: Date(timeIntervalSince1970: 300))
    )
    try repository.save(
      Note(contactId: UUID(), contactName: "다른 연락처", content: "중간", createdAt: Date(timeIntervalSince1970: 200))
    )

    let notes = try repository.fetchAll()

    XCTAssertEqual(notes.map(\.content), ["가장 최신", "중간", "가장 오래됨"])
  }

  @MainActor
  func testDeleteRemovesEveryRowWithTheSameId() async throws {
    let container = try makeContainer()
    let repository = SwiftDataNoteRepository(modelContext: container.mainContext)
    let noteId = UUID()
    for content in ["첫 번째", "두 번째"] {
      container.mainContext.insert(
        StoredNote(
          id: noteId,
          contactId: nil,
          contactName: "중복",
          content: content,
          imageData: nil,
          profileImageData: nil,
          isFavorite: false
        )
      )
    }
    try container.mainContext.save()

    try repository.delete(id: noteId)

    XCTAssertTrue(try repository.fetchAll().isEmpty)
  }

  @MainActor
  func testFetchAllReturnsEmptyArrayForEmptyStore() async throws {
    let container = try makeContainer()
    let repository = SwiftDataNoteRepository(modelContext: container.mainContext)

    XCTAssertTrue(try repository.fetchAll().isEmpty)
  }

  @MainActor
  func testFetchWithNilContactIdReturnsOnlyUnlinkedNotes() async throws {
    let container = try makeContainer()
    let repository = SwiftDataNoteRepository(modelContext: container.mainContext)

    try repository.save(Note(contactId: UUID(), contactName: "연결됨", content: "연결된 노트"))
    try repository.save(Note(contactId: nil, contactName: "연결 안 됨", content: "연결 안 된 노트"))

    XCTAssertEqual(try repository.fetch(contactId: nil).map(\.content), ["연결 안 된 노트"])
    XCTAssertEqual(try repository.fetchAll().count, 2)
  }

  @MainActor
  func testSaveUpdatesExistingNoteWithoutCreatingDuplicate() async throws {
    let container = try makeContainer()
    let repository = SwiftDataNoteRepository(modelContext: container.mainContext)
    let noteId = UUID()

    try repository.save(
      Note(
        id: noteId,
        contactName: "연락처",
        content: "수정 전"
      )
    )
    try repository.save(
      Note(
        id: noteId,
        contactName: "연락처",
        content: "수정 후"
      )
    )

    let storedNotes = try container.mainContext.fetch(
      FetchDescriptor<StoredNote>()
    )
    XCTAssertEqual(storedNotes.count, 1)
    XCTAssertEqual(storedNotes.first?.content, "수정 후")
  }

  @MainActor
  func testDeleteAllRemovesOnlyNotesForRequestedContact() async throws {
    let container = try makeContainer()
    let repository = SwiftDataNoteRepository(modelContext: container.mainContext)
    let targetContactId = UUID()
    let otherContactId = UUID()

    try repository.save(
      Note(contactId: targetContactId, contactName: "삭제 대상", content: "첫 번째")
    )
    try repository.save(
      Note(contactId: targetContactId, contactName: "삭제 대상", content: "두 번째")
    )
    try repository.save(
      Note(contactId: otherContactId, contactName: "유지 대상", content: "남아야 함")
    )

    try repository.deleteAll(contactIds: [targetContactId])

    XCTAssertTrue(try repository.fetch(contactId: targetContactId).isEmpty)
    XCTAssertEqual(
      try repository.fetch(contactId: otherContactId).map(\.content),
      ["남아야 함"]
    )
  }

  @MainActor
  func testDeleteAllRemovesNotesForMultipleContactsAtOnce() async throws {
    let container = try makeContainer()
    let repository = SwiftDataNoteRepository(modelContext: container.mainContext)
    let firstContactId = UUID()
    let secondContactId = UUID()
    let keptContactId = UUID()

    try repository.save(Note(contactId: firstContactId, contactName: "첫째", content: "삭제 1"))
    try repository.save(Note(contactId: secondContactId, contactName: "둘째", content: "삭제 2"))
    try repository.save(Note(contactId: keptContactId, contactName: "유지", content: "유지"))

    try repository.deleteAll(contactIds: [firstContactId, secondContactId])

    XCTAssertTrue(try repository.fetch(contactId: firstContactId).isEmpty)
    XCTAssertTrue(try repository.fetch(contactId: secondContactId).isEmpty)
    XCTAssertEqual(try repository.fetch(contactId: keptContactId).map(\.content), ["유지"])
  }

  @MainActor
  func testSavePersistsPinnedState() async throws {
    let container = try makeContainer()
    let repository = SwiftDataNoteRepository(modelContext: container.mainContext)
    let note = Note(contactName: "연락처", content: "고정 메모", isPinned: true)

    try repository.save(note)

    let savedNote = try XCTUnwrap(repository.fetch(contactId: nil).first)
    XCTAssertTrue(savedNote.isPinned)
  }

  @MainActor
  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: StoredNote.self,
      StoredNoteLinkPreview.self,
      StoredNoteImageAnalysis.self,
      StoredNoteVoiceTranscript.self,
      StoredNoteEmbedding.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
  }
}
