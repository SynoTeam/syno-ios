import XCTest
@testable import Syno

final class NotesViewModelTests: XCTestCase {
  @MainActor
  func testReplaceNotesKeepsLatestNoteForEachContact() async {
    let firstContactId = UUID()
    let secondContactId = UUID()
    let oldDate = Date(timeIntervalSince1970: 100)
    let newDate = Date(timeIntervalSince1970: 200)
    let viewModel = NotesViewModel()

    viewModel.replaceNotes([
      Note(
        contactId: firstContactId,
        contactName: "첫 번째",
        content: "이전 메모",
        createdAt: oldDate
      ),
      Note(
        contactId: secondContactId,
        contactName: "두 번째",
        content: "다른 연락처 메모",
        createdAt: oldDate
      ),
      Note(
        contactId: firstContactId,
        contactName: "첫 번째",
        content: "최신 메모",
        createdAt: newDate
      )
    ])

    XCTAssertEqual(viewModel.notes.count, 2)
    XCTAssertEqual(viewModel.notes.first?.content, "최신 메모")
    XCTAssertFalse(viewModel.notes.contains { $0.content == "이전 메모" })
  }

  @MainActor
  func testReplaceNotesReflectsFavoriteFromContact() async {
    let favoriteContactId = UUID()
    let viewModel = NotesViewModel()

    viewModel.replaceNotes(
      [
        Note(
          contactId: favoriteContactId,
          contactName: "즐겨찾기",
          content: "이전 메모",
          createdAt: Date(timeIntervalSince1970: 100)
        ),
        Note(
          contactId: favoriteContactId,
          contactName: "즐겨찾기",
          content: "최신 메모",
          createdAt: Date(timeIntervalSince1970: 200)
        )
      ],
      favoriteContactIds: [favoriteContactId]
    )

    XCTAssertEqual(viewModel.notes.count, 1)
    XCTAssertEqual(viewModel.notes.first?.content, "최신 메모")
    XCTAssertEqual(viewModel.notes.first?.isFavorite, true)
    XCTAssertEqual(viewModel.availableFilters, NoteFilter.allCases)
  }
}
