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
  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: StoredContact.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
  }
}
