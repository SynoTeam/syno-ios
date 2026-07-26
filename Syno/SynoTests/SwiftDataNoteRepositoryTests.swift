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
  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: StoredNote.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
  }
}
