import SwiftData
import XCTest
@testable import Syno

final class GroupServiceTests: XCTestCase {
  @MainActor
  func testBackfillCreatesDistinctGroupsFromExistingContacts() async throws {
    // 컨테이너가 먼저 해제되면 mainContext 사용 시 크래시가 나므로 테스트 동안 붙잡아 둡니다.
    let container = try makeContainer()
    let context = container.mainContext
    context.insert(StoredContact(contact: Contact(name: "A", role: "", company: "", group: "스터디")))
    context.insert(StoredContact(contact: Contact(name: "B", role: "", company: "", group: "study")))
    context.insert(StoredContact(contact: Contact(name: "C", role: "", company: "", group: "스터디")))
    try context.save()

    try makeService(context: context).backfillGroupsIfNeeded()

    let groups = try context.fetch(FetchDescriptor<StoredGroup>(sortBy: [SortDescriptor(\.sortIndex)]))
    XCTAssertEqual(groups.map(\.name), ["스터디", "study"])
    XCTAssertEqual(groups.map(\.sortIndex), [0, 1])
  }

  @MainActor
  func testDeleteGroupClearsMatchingContactGroups() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    let group = StoredGroup(name: "프로젝트", sortIndex: 0)
    let matchingContact = StoredContact(contact: Contact(name: "A", role: "", company: "", group: "프로젝트"))
    let otherContact = StoredContact(contact: Contact(name: "B", role: "", company: "", group: "친구"))
    context.insert(group)
    context.insert(matchingContact)
    context.insert(otherContact)
    try context.save()

    try GroupService(modelContext: context).deleteGroup(group)

    XCTAssertTrue(try context.fetch(FetchDescriptor<StoredGroup>()).isEmpty)
    XCTAssertEqual(matchingContact.group, "")
    XCTAssertEqual(otherContact.group, "친구")
  }

  @MainActor
  func testUpdateSortIndexesPersistsCustomOrder() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    let first = StoredGroup(name: "첫 번째", sortIndex: 0)
    let second = StoredGroup(name: "두 번째", sortIndex: 1)
    context.insert(first)
    context.insert(second)
    try context.save()

    try GroupService(modelContext: context).updateSortIndexes(for: [second, first])

    let groups = try context.fetch(FetchDescriptor<StoredGroup>(sortBy: [SortDescriptor(\.sortIndex)]))
    XCTAssertEqual(groups.map(\.name), ["두 번째", "첫 번째"])
  }

  @MainActor
  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: StoredContact.self,
      StoredGroup.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    )
  }

  @MainActor
  private func makeService(context: ModelContext) -> GroupService {
    let suiteName = "GroupServiceTests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName)!
    userDefaults.removePersistentDomain(forName: suiteName)
    return GroupService(modelContext: context, userDefaults: userDefaults)
  }
}
