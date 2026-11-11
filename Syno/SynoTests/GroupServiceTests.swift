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

    try GroupService(modelContext: context).deleteGroup(named: group.name)

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

    try GroupService(modelContext: context).updateSortOrder([second.name, first.name])

    let groups = try context.fetch(FetchDescriptor<StoredGroup>(sortBy: [SortDescriptor(\.sortIndex)]))
    XCTAssertEqual(groups.map(\.name), ["두 번째", "첫 번째"])
  }

  // MARK: - 그룹 만들기

  @MainActor
  func testCreateGroupTrimsNameAndAppendsToTheEnd() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    context.insert(StoredGroup(name: "스터디", sortIndex: 0))
    context.insert(StoredGroup(name: "회사", sortIndex: 1))
    try context.save()
    let service = makeService(context: context)

    let group = try service.createGroup(named: "  동아리 ")

    XCTAssertEqual(group, ContactGroup(name: "동아리", sortIndex: 2))
    XCTAssertEqual(try service.fetchGroups().map(\.name), ["스터디", "회사", "동아리"])
  }

  @MainActor
  func testCreateGroupReturnsExistingGroupForCaseVariant() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    context.insert(StoredGroup(name: "Study", sortIndex: 0))
    try context.save()
    let service = makeService(context: context)

    let group = try service.createGroup(named: "STUDY")

    XCTAssertEqual(group, ContactGroup(name: "Study", sortIndex: 0))
    XCTAssertEqual(try context.fetch(FetchDescriptor<StoredGroup>()).count, 1)
  }

  @MainActor
  func testCreateGroupIgnoresBlankName() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    let service = makeService(context: context)

    XCTAssertNil(try service.createGroup(named: "   "))
    XCTAssertTrue(try context.fetch(FetchDescriptor<StoredGroup>()).isEmpty)
  }

  // MARK: - 같은 이름의 중복 행 (기기마다 백필한 그룹이 CloudKit으로 합쳐질 때 생김)

  @MainActor
  func testFetchGroupsShowsDuplicateRowsAsOneGroup() async throws {
    let container = try makeContainer()
    let context = try insertDuplicatedGroups(into: container)

    let groups = try makeService(context: context).fetchGroups()

    XCTAssertEqual(groups.map(\.name), ["Study", "Work"])
  }

  @MainActor
  func testDeleteGroupNamedRemovesEveryDuplicateRow() async throws {
    let container = try makeContainer()
    let context = try insertDuplicatedGroups(into: container)

    try makeService(context: context).deleteGroup(named: "Study")

    let names = try context.fetch(FetchDescriptor<StoredGroup>()).map(\.name)
    XCTAssertEqual(names, ["Work"])
  }

  /// 중복 행에 같은 순서를 주면 읽을 때 대표 이름(Study/STUDY)이 매번 달라질 수 있어서,
  /// 순서를 저장할 때 화면에서 보던 이름의 행 하나만 남기고 정리한다.
  @MainActor
  func testUpdateSortOrderMergesDuplicateRowsIntoTheShownName() async throws {
    let container = try makeContainer()
    let context = try insertDuplicatedGroups(into: container)
    let service = makeService(context: context)

    try service.updateSortOrder(["Work", "Study"])

    XCTAssertEqual(try service.fetchGroups().map(\.name), ["Work", "Study"])
    let rows = try context.fetch(FetchDescriptor<StoredGroup>(sortBy: [SortDescriptor(\.sortIndex)]))
    XCTAssertEqual(rows.map(\.name), ["Work", "Study"])
    XCTAssertEqual(rows.map(\.sortIndex), [0, 1])
  }

  /// "Study"가 같은 이름과 대소문자만 다른 이름으로 3개 행에 중복된 상태를 만듭니다.
  @MainActor
  private func insertDuplicatedGroups(into container: ModelContainer) throws -> ModelContext {
    let context = container.mainContext
    context.insert(StoredGroup(name: "Study", sortIndex: 0))
    context.insert(StoredGroup(name: "Work", sortIndex: 1))
    context.insert(StoredGroup(name: "Study", sortIndex: 2))
    context.insert(StoredGroup(name: "STUDY", sortIndex: 3))
    try context.save()
    return context
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
