import Foundation
import Testing
@testable import Syno

/// 연락처 추가·편집 → 그룹 선택 시트의 화면 상태 규칙입니다 (#122).
@MainActor
struct GroupSelectionViewModelTests {
  private let savedGroups = [
    ContactGroup(name: "Study", sortIndex: 0),
    ContactGroup(name: "회사", sortIndex: 1),
  ]

  @Test("저장된 그룹을 사용자 설정 순서로 보여준다")
  func loadShowsGroupsInSavedOrder() {
    let viewModel = makeViewModel(selectedGroup: "")

    viewModel.load()

    #expect(viewModel.groups.map(\.name) == ["Study", "회사"])
  }

  @Test("다른 그룹을 고르면 선택이 바뀌고 입력 중이던 새 그룹은 닫힌다")
  func selectingGroupCancelsNewGroupInput() {
    let viewModel = makeViewModel(selectedGroup: "")
    viewModel.load()
    viewModel.startAddingGroup()
    viewModel.newGroupName = "임시"

    viewModel.select("회사")

    #expect(viewModel.selectedGroup == "회사")
    #expect(!viewModel.isAddingNewGroup)
    #expect(viewModel.newGroupName.isEmpty)
  }

  @Test("새 그룹을 만들면 목록에 추가하고 선택한다")
  func confirmingNewGroupCreatesAndSelectsIt() {
    let repository = GroupRepositorySpy(groups: savedGroups)
    let viewModel = makeViewModel(selectedGroup: "", repository: repository)
    viewModel.load()
    viewModel.startAddingGroup()
    viewModel.newGroupName = " 동아리 "

    let didCreate = viewModel.confirmNewGroup()

    #expect(didCreate)
    #expect(repository.createdNames == ["동아리"])
    #expect(viewModel.selectedGroup == "동아리")
    #expect(viewModel.groups.map(\.name) == ["Study", "회사", "동아리"])
    #expect(!viewModel.isAddingNewGroup)
  }

  @Test("대소문자만 다른 이름이면 새로 만들지 않고 기존 그룹을 고른다")
  func confirmingCaseVariantSelectsExistingGroup() {
    let repository = GroupRepositorySpy(groups: savedGroups)
    let viewModel = makeViewModel(selectedGroup: "", repository: repository)
    viewModel.load()
    viewModel.startAddingGroup()
    viewModel.newGroupName = "study"

    viewModel.confirmNewGroup()

    #expect(repository.createdNames.isEmpty)
    #expect(viewModel.selectedGroup == "Study")
    #expect(viewModel.groups.count == 2)
  }

  @Test("새 그룹을 입력하던 중 완료하면 그 그룹을 만들어 적용한다")
  func applyingWhileTypingCreatesAndReturnsNewGroup() {
    let viewModel = makeViewModel(selectedGroup: "회사")
    viewModel.load()
    viewModel.startAddingGroup()
    viewModel.newGroupName = "동아리"

    #expect(viewModel.apply() == "동아리")
  }

  @Test("입력을 시작만 하고 비워 둔 채 완료하면 기존 선택을 적용한다")
  func applyingWithEmptyNewGroupKeepsSelection() {
    let viewModel = makeViewModel(selectedGroup: "회사")
    viewModel.load()
    viewModel.startAddingGroup()
    viewModel.newGroupName = "   "

    #expect(viewModel.apply() == "회사")
  }

  @Test("그룹을 만들지 못하면 적용하지 않고 실패를 알린다")
  func applyingFailsWhenCreationFails() {
    let repository = GroupRepositorySpy(groups: savedGroups)
    let viewModel = makeViewModel(selectedGroup: "회사", repository: repository)
    viewModel.load()
    viewModel.startAddingGroup()
    viewModel.newGroupName = "동아리"
    repository.shouldFail = true

    #expect(viewModel.apply() == nil)
    #expect(viewModel.failureMessage == "그룹 추가에 실패했습니다")
    #expect(viewModel.isAddingNewGroup)
  }

  @Test("연락처에 대소문자만 다르게 저장된 그룹은 저장된 그룹 이름으로 적용한다")
  func applyingUsesCanonicalGroupName() {
    let viewModel = makeViewModel(selectedGroup: "study")
    viewModel.load()

    #expect(viewModel.apply() == "Study")
  }

  @Test("새 그룹 이름은 20자까지만 입력된다", arguments: [
    (String(repeating: "가", count: 20), 20),
    (String(repeating: "가", count: 21), 20),
  ])
  func newGroupNameIsLimitedTo20Characters(input: String, expectedCount: Int) {
    let viewModel = makeViewModel(selectedGroup: "")

    viewModel.newGroupName = input

    #expect(viewModel.newGroupName.count == expectedCount)
  }

  @Test("입력 지우기 버튼은 내용이 있으면 지우고, 비어 있으면 입력을 닫는다")
  func clearOrCancelNewGroup() {
    let viewModel = makeViewModel(selectedGroup: "")
    viewModel.startAddingGroup()
    viewModel.newGroupName = "임시"

    viewModel.clearOrCancelNewGroup()
    #expect(viewModel.newGroupName.isEmpty)
    #expect(viewModel.isAddingNewGroup)

    viewModel.clearOrCancelNewGroup()
    #expect(!viewModel.isAddingNewGroup)
  }

  private func makeViewModel(
    selectedGroup: String,
    repository: GroupRepositorySpy? = nil
  ) -> GroupSelectionViewModel {
    GroupSelectionViewModel(
      selectedGroup: selectedGroup,
      groupRepository: repository ?? GroupRepositorySpy(groups: savedGroups)
    )
  }
}
