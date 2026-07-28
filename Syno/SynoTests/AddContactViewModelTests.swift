import XCTest
@testable import Syno

final class AddContactViewModelTests: XCTestCase {
  @MainActor
  func testEditModePreservesOriginalIdentityAndAdditionalFields() {
    let original = Contact(
      id: UUID(),
      name: "김 테스트",
      role: "Product Designer",
      company: "Syno",
      email: "test@syno.app",
      phone: "+82 01012345678",
      url: "https://syno.app",
      address: "서울특별시 중구",
      birthday: Date(timeIntervalSince1970: 1_000_000),
      anniversary: Date(timeIntervalSince1970: 2_000_000),
      socialLinks: [ContactSocialLink(platform: "Instagram", handle: "@syno")],
      group: "디자인",
      note: "기존 메모",
      isFavorite: true,
      isMe: true
    )
    let viewModel = AddContactViewModel(contact: original)

    let editedContact = viewModel.makeContact()

    XCTAssertEqual(editedContact.id, original.id)
    XCTAssertEqual(editedContact.isFavorite, true)
    XCTAssertEqual(editedContact.isMe, true)
    XCTAssertEqual(editedContact.role, original.role)
    XCTAssertEqual(editedContact.company, original.company)
    XCTAssertEqual(editedContact.address, original.address)
    XCTAssertEqual(editedContact.birthday, original.birthday)
    XCTAssertEqual(editedContact.anniversary, original.anniversary)
    XCTAssertEqual(editedContact.socialLinks, original.socialLinks)
  }
}
