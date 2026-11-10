import Foundation
import Testing
@testable import Syno

/// 노트 → 그룹 편집하기 시트의 화면 상태 규칙입니다 (#120).
@MainActor
struct GroupManagementViewModelTests {
  private let savedGroups = [
    ContactGroup(name: "스터디", sortIndex: 0),
    ContactGroup(name: "회사", sortIndex: 1),
    ContactGroup(name: "가족", sortIndex: 2),
  ]

  @Test("가나다순이면 이름 순, 사용자 설정 순이면 저장된 순서로 보여준다", arguments: [
    (GroupManagementViewModel.SortMode.alphabetical, ["가족", "스터디", "회사"]),
    (GroupManagementViewModel.SortMode.custom, ["스터디", "회사", "가족"]),
  ])
  func displayedGroupsFollowSortMode(sortMode: GroupManagementViewModel.SortMode, expected: [String]) {
    let viewModel = makeViewModel(repository: GroupRepositorySpy(groups: savedGroups))
    viewModel.load()

    viewModel.sortMode = sortMode

    #expect(viewModel.displayedGroups.map(\.name) == expected)
  }

  @Test("정렬 방식은 다시 열어도 유지된다")
  func sortModeIsRemembered() {
    let userDefaults = makeUserDefaults()
    let first = makeViewModel(repository: GroupRepositorySpy(groups: savedGroups), userDefaults: userDefaults)
    first.sortMode = .custom

    let reopened = makeViewModel(repository: GroupRepositorySpy(groups: savedGroups), userDefaults: userDefaults)

    #expect(reopened.sortMode == .custom)
  }

  @Test("처음 열면 가나다순이다")
  func defaultSortModeIsAlphabetical() {
    let viewModel = makeViewModel(repository: GroupRepositorySpy(groups: savedGroups))

    #expect(viewModel.sortMode == .alphabetical)
    #expect(!viewModel.canReorder)
  }

  @Test("사용자 설정 순에서 순서를 바꾸면 바뀐 순서를 저장한다")
  func moveInCustomOrderSavesNewOrder() {
    let repository = GroupRepositorySpy(groups: savedGroups)
    let viewModel = makeViewModel(repository: repository)
    viewModel.load()
    viewModel.sortMode = .custom

    viewModel.moveGroups(from: IndexSet(integer: 2), to: 0)

    #expect(repository.savedSortOrders == [["가족", "스터디", "회사"]])
    #expect(viewModel.displayedGroups.map(\.name) == ["가족", "스터디", "회사"])
  }

  @Test("가나다순에서는 순서를 바꾸지 않는다")
  func moveInAlphabeticalOrderDoesNothing() {
    let repository = GroupRepositorySpy(groups: savedGroups)
    let viewModel = makeViewModel(repository: repository)
    viewModel.load()
    viewModel.sortMode = .alphabetical

    viewModel.moveGroups(from: IndexSet(integer: 2), to: 0)

    #expect(repository.savedSortOrders.isEmpty)
  }

  @Test("그룹을 삭제하면 목록에서 사라진다")
  func deleteRemovesGroup() {
    let repository = GroupRepositorySpy(groups: savedGroups)
    let viewModel = makeViewModel(repository: repository)
    viewModel.load()

    viewModel.deleteGroup(named: "회사")

    #expect(repository.deletedNames == ["회사"])
    #expect(viewModel.displayedGroups.map(\.name) == ["가족", "스터디"])
    #expect(viewModel.failureMessage == nil)
  }

  @Test("삭제에 실패하면 목록을 그대로 두고 실패 문구를 알린다")
  func deleteFailureKeepsGroupsAndReportsFailure() {
    let repository = GroupRepositorySpy(groups: savedGroups)
    repository.shouldFail = true
    let viewModel = makeViewModel(repository: repository)
    viewModel.load()

    viewModel.deleteGroup(named: "회사")

    #expect(viewModel.displayedGroups.count == 3)
    #expect(viewModel.failureMessage == "그룹 삭제에 실패했습니다")
  }

  @Test("순서 저장에 실패하면 이전 순서를 유지하고 실패 문구를 알린다")
  func moveFailureKeepsOrderAndReportsFailure() {
    let repository = GroupRepositorySpy(groups: savedGroups)
    repository.shouldFail = true
    let viewModel = makeViewModel(repository: repository)
    viewModel.load()
    viewModel.sortMode = .custom

    viewModel.moveGroups(from: IndexSet(integer: 2), to: 0)

    #expect(viewModel.displayedGroups.map(\.name) == ["스터디", "회사", "가족"])
    #expect(viewModel.failureMessage == "그룹 순서 저장에 실패했습니다")
  }

  private func makeViewModel(
    repository: GroupRepositorySpy,
    userDefaults: UserDefaults? = nil
  ) -> GroupManagementViewModel {
    GroupManagementViewModel(groupRepository: repository, userDefaults: userDefaults ?? makeUserDefaults())
  }

  private func makeUserDefaults() -> UserDefaults {
    let suiteName = "GroupManagementViewModelTests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName)!
    userDefaults.removePersistentDomain(forName: suiteName)
    return userDefaults
  }
}

@MainActor
private final class GroupRepositorySpy: GroupRepository {
  private var groups: [ContactGroup]
  var shouldFail = false
  private(set) var deletedNames: [String] = []
  private(set) var savedSortOrders: [[String]] = []

  init(groups: [ContactGroup]) {
    self.groups = groups
  }

  func fetchGroups() throws -> [ContactGroup] {
    groups.sorted { $0.sortIndex < $1.sortIndex }
  }

  func deleteGroup(named name: String) throws {
    if shouldFail { throw SpyError.failed }
    deletedNames.append(name)
    groups.removeAll { $0.name == name }
  }

  func updateSortOrder(_ names: [String]) throws {
    if shouldFail { throw SpyError.failed }
    savedSortOrders.append(names)
    groups = names.enumerated().map { ContactGroup(name: $1, sortIndex: $0) }
  }

  private enum SpyError: Error {
    case failed
  }
}
