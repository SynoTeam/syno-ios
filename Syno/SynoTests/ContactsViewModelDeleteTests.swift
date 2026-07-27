import XCTest
@testable import Syno

final class ContactsViewModelDeleteTests: XCTestCase {
  @MainActor
  func testDeleteContactsRemovesAllSelectedContactsOnSuccess() async {
    let first = Contact(name: "Apple", role: "", company: "")
    let second = Contact(name: "Apex", role: "", company: "")
    let profile = Contact(
      name: "내 프로필",
      role: "",
      company: "",
      isMe: true
    )
    let repository = DeleteTestContactRepository()
    let viewModel = ContactsViewModel(
      repository: repository,
      contacts: [profile, first, second],
      myProfileId: profile.id
    )

    let deletedCount = viewModel.deleteContacts(ids: [first.id, second.id])

    XCTAssertEqual(deletedCount, 2)
    XCTAssertEqual(viewModel.contacts, [profile])
    XCTAssertEqual(repository.deletedIDs, [first.id, second.id])
    XCTAssertNil(viewModel.persistenceError)
  }

  @MainActor
  func testDeleteContactsKeepsFailedContactSelectedAfterPartialFailure() async {
    let first = Contact(name: "Apple", role: "", company: "")
    let second = Contact(name: "Apex", role: "", company: "")
    let repository = DeleteTestContactRepository(failingID: second.id)
    let viewModel = ContactsViewModel(
      repository: repository,
      contacts: [first, second],
      myProfileId: UUID()
    )

    let deletedCount = viewModel.deleteContacts(ids: [first.id, second.id])

    XCTAssertNil(deletedCount)
    XCTAssertEqual(viewModel.contacts, [second])
    XCTAssertEqual(repository.deletedIDs, [first.id])
    XCTAssertEqual(
      viewModel.persistenceError,
      "연락처를 삭제하지 못했습니다. 다시 시도해주세요."
    )
  }
}

@MainActor
private final class DeleteTestContactRepository: ContactRepository {
  let failingID: Contact.ID?
  private(set) var deletedIDs: [Contact.ID] = []

  init(failingID: Contact.ID? = nil) {
    self.failingID = failingID
  }

  func fetchAll() throws -> [Contact] {
    []
  }

  func save(_ contact: Contact) throws {}

  func delete(id: Contact.ID) throws {
    if id == failingID {
      throw DeleteTestError.deleteFailed
    }
    deletedIDs.append(id)
  }
}

private enum DeleteTestError: Error {
  case deleteFailed
}
