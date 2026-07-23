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
  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: StoredContact.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
  }
}
