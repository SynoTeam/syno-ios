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
    XCTAssertEqual(viewModel.availableFilters, [.all])
  }

  @MainActor
  func testPinnedNotesStayAtTopAndUnpinnedNotesKeepSortOrder() async {
    let pinnedContactA = UUID()
    let pinnedContactB = UUID()
    let viewModel = NotesViewModel()
    viewModel.replaceNotes(
      [
        Note(contactName: "가", content: "일반 최신", createdAt: Date(timeIntervalSince1970: 300)),
        Note(contactId: pinnedContactA, contactName: "나", content: "고정 오래됨", createdAt: Date(timeIntervalSince1970: 100)),
        Note(contactId: pinnedContactB, contactName: "다", content: "고정 최신", createdAt: Date(timeIntervalSince1970: 200))
      ],
      pinnedContactIds: [pinnedContactA, pinnedContactB]
    )

    XCTAssertEqual(
      viewModel.filteredNotes.map(\.content),
      ["고정 최신", "고정 오래됨", "일반 최신"]
    )

    viewModel.sortOrder = .name

    XCTAssertEqual(
      viewModel.filteredNotes.map(\.content),
      ["고정 최신", "고정 오래됨", "일반 최신"]
    )
  }

  @MainActor
  func testUnpinningReturnsNoteToExistingSortOrder() async {
    let pinnedContact = UUID()
    let viewModel = NotesViewModel()
    viewModel.replaceNotes(
      [
        Note(contactId: pinnedContact, contactName: "가", content: "가", createdAt: Date(timeIntervalSince1970: 100)),
        Note(contactName: "나", content: "나", createdAt: Date(timeIntervalSince1970: 200))
      ],
      pinnedContactIds: [pinnedContact]
    )

    viewModel.replaceNotes([
      Note(contactId: pinnedContact, contactName: "가", content: "가", createdAt: Date(timeIntervalSince1970: 100)),
      Note(contactName: "나", content: "나", createdAt: Date(timeIntervalSince1970: 200))
    ])

    XCTAssertEqual(viewModel.filteredNotes.map(\.content), ["나", "가"])
  }

  @MainActor
  func testIsEmptyReflectsSelectedFilterNotWholeList() async {
    let viewModel = NotesViewModel()
    viewModel.replaceNotes(
      [
        Note(contactName: "가", content: "메모", createdAt: Date(timeIntervalSince1970: 100))
      ],
      groupNames: ["Apple", "Apex"],
      groupNamesByContactID: [:]
    )

    XCTAssertFalse(viewModel.isEmpty)

    viewModel.selectedFilter = .group("Apex")

    XCTAssertTrue(viewModel.isEmpty)
  }
}
