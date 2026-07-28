import SwiftData
import XCTest
@testable import Syno

final class ContactProfileIdentityTests: XCTestCase {
  @MainActor
  func testContactRepositoryPreservesMyProfileIdAcrossFreshContext() async throws {
    let container = try makeContainer()
    let profileId = UUID()
    let repository = SwiftDataContactRepository(modelContext: container.mainContext)
    try repository.save(
      Contact(
        id: profileId,
        name: "내 프로필",
        role: "",
        company: "",
        isMe: true
      )
    )

    let freshContext = ModelContext(container)
    let relaunchedRepository = SwiftDataContactRepository(modelContext: freshContext)
    let contacts = try relaunchedRepository.fetchAll()

    XCTAssertEqual(contacts.first?.id, profileId)
    XCTAssertEqual(contacts.first?.isMe, true)
  }

  @MainActor
  func testSaveUpdatesExistingContactWithoutCreatingDuplicate() async throws {
    let container = try makeContainer()
    let repository = SwiftDataContactRepository(modelContext: container.mainContext)
    let contactId = UUID()

    try repository.save(
      Contact(
        id: contactId,
        name: "수정 전",
        role: "",
        company: ""
      )
    )
    try repository.save(
      Contact(
        id: contactId,
        name: "수정 후",
        role: "",
        company: ""
      )
    )

    let storedContacts = try container.mainContext.fetch(
      FetchDescriptor<StoredContact>()
    )
    XCTAssertEqual(storedContacts.count, 1)
    XCTAssertEqual(storedContacts.first?.name, "수정 후")
  }

  @MainActor
  func testContactAdditionalFieldsRoundTripThroughSwiftData() async throws {
    let container = try makeContainer()
    let repository = SwiftDataContactRepository(modelContext: container.mainContext)
    let contact = Contact(
      name: "김테스트",
      role: "",
      company: "",
      address: "서울특별시 중구 세종대로 110",
      birthday: Date(timeIntervalSince1970: 1_000_000),
      anniversary: Date(timeIntervalSince1970: 2_000_000),
      socialLinks: [
        ContactSocialLink(platform: "Instagram", handle: "@syno"),
        ContactSocialLink(platform: "LinkedIn", handle: "syno-team")
      ]
    )
    try repository.save(contact)

    let freshContext = ModelContext(container)
    let fetchedContact = try SwiftDataContactRepository(modelContext: freshContext).fetchAll().first

    XCTAssertEqual(fetchedContact?.address, contact.address)
    XCTAssertEqual(fetchedContact?.birthday, contact.birthday)
    XCTAssertEqual(fetchedContact?.anniversary, contact.anniversary)
    XCTAssertEqual(fetchedContact?.socialLinks, contact.socialLinks)
  }

  @MainActor
  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: StoredContact.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
  }
}
