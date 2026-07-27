import XCTest
@testable import Syno

final class ContactsViewModelFavoriteTests: XCTestCase {
  @MainActor
  func testFavoriteCanBeToggledAndRestored() async {
    let contact = Contact(
      name: "홍길동",
      role: "",
      company: "",
      isFavorite: true
    )
    let repository = FavoriteTestContactRepository(contacts: [contact])
    let viewModel = ContactsViewModel(
      repository: repository,
      contacts: [contact],
      myProfileId: UUID()
    )

    let isFavoriteAfterToggle = viewModel.toggleFavorite(id: contact.id)
    let undoSucceeded = viewModel.setFavorite(
      id: contact.id,
      isFavorite: true
    )

    XCTAssertEqual(isFavoriteAfterToggle, false)
    XCTAssertTrue(undoSucceeded)
    XCTAssertEqual(viewModel.contacts.first?.isFavorite, true)
    XCTAssertEqual(repository.savedContacts.map(\.isFavorite), [false, true])
  }

  @MainActor
  func testFavoriteSaveFailureKeepsStateAndProvidesToastMessage() async {
    let contact = Contact(
      name: "홍길동",
      role: "",
      company: "",
      isFavorite: true
    )
    let repository = FavoriteTestContactRepository(
      contacts: [contact],
      shouldFailSave: true
    )
    let viewModel = ContactsViewModel(
      repository: repository,
      contacts: [contact],
      myProfileId: UUID()
    )

    let result = viewModel.toggleFavorite(id: contact.id)

    XCTAssertNil(result)
    XCTAssertEqual(viewModel.contacts.first?.isFavorite, true)
    XCTAssertEqual(
      viewModel.persistenceError,
      "연락처를 저장하지 못했습니다. 다시 시도해주세요."
    )
  }
}

@MainActor
private final class FavoriteTestContactRepository: ContactRepository {
  let contacts: [Contact]
  let shouldFailSave: Bool
  private(set) var savedContacts: [Contact] = []

  init(
    contacts: [Contact],
    shouldFailSave: Bool = false
  ) {
    self.contacts = contacts
    self.shouldFailSave = shouldFailSave
  }

  func fetchAll() throws -> [Contact] {
    contacts
  }

  func save(_ contact: Contact) throws {
    if shouldFailSave {
      throw FavoriteTestError.saveFailed
    }
    savedContacts.append(contact)
  }

  func delete(id: Contact.ID) throws {}
}

private enum FavoriteTestError: Error {
  case saveFailed
}
