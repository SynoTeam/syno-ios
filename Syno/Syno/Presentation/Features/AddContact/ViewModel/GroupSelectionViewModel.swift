import Foundation
import Observation

/// 연락처 추가·편집, 내 프로필 편집의 그룹 선택 시트 상태입니다.
/// 그룹을 고르거나 새 그룹을 만들어 고릅니다.
@MainActor
@Observable
final class GroupSelectionViewModel {
  /// 새 그룹 이름의 최대 글자 수입니다.
  static let newGroupNameLimit = 20

  /// 저장된 순서대로의 그룹입니다.
  private(set) var groups: [ContactGroup] = []
  /// 지금 체크된 그룹 이름입니다. 빈 문자열은 "선택 안 함"입니다.
  private(set) var selectedGroup: String
  private(set) var isAddingNewGroup = false
  var newGroupName = "" {
    didSet {
      if newGroupName.count > Self.newGroupNameLimit {
        newGroupName = String(newGroupName.prefix(Self.newGroupNameLimit))
      }
    }
  }
  /// 실패를 알릴 문구입니다. 화면이 토스트로 보여준 뒤 비웁니다.
  var failureMessage: String?

  private let groupRepository: any GroupRepository

  init(selectedGroup: String, groupRepository: any GroupRepository) {
    self.selectedGroup = selectedGroup
    self.groupRepository = groupRepository
  }

  func load() {
    do {
      groups = try groupRepository.fetchGroups()
    } catch {
      groups = []
    }
    // 연락처에 대소문자만 다르게 저장된 그룹도 열 때부터 해당 행에 체크가 보이도록 저장된 이름으로 맞춘다.
    selectedGroup = canonicalName(for: selectedGroup)
  }

  /// 그룹을 고릅니다. 새 그룹을 입력하다 다른 그룹을 고르면 마지막 선택이 적용되도록 입력을 접습니다.
  func select(_ group: String) {
    selectedGroup = group
    cancelNewGroup()
  }

  func startAddingGroup() {
    isAddingNewGroup = true
  }

  /// 입력한 내용이 있으면 지우고, 이미 비어 있으면 그룹 추가 입력을 닫습니다.
  func clearOrCancelNewGroup() {
    if newGroupName.isEmpty {
      cancelNewGroup()
    } else {
      newGroupName = ""
    }
  }

  /// 입력한 이름으로 그룹을 만들고 고릅니다. 만들지 못하면 실패를 알리고 false를 반환합니다.
  @discardableResult
  func confirmNewGroup() -> Bool {
    do {
      if let group = try groupRepository.createGroup(named: newGroupName) {
        if !groups.contains(group) {
          groups.append(group)
        }
        selectedGroup = group.name
      }
      cancelNewGroup()
      return true
    } catch {
      failureMessage = "그룹 추가에 실패했습니다"
      return false
    }
  }

  /// 연락처에 적용할 그룹 이름을 반환합니다.
  /// 새 그룹을 입력하던 중이면 먼저 만들고, 만들지 못하면 nil을 반환해 시트를 닫지 않게 합니다.
  func apply() -> String? {
    let hasPendingGroup = isAddingNewGroup
      && !newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    if hasPendingGroup, !confirmNewGroup() {
      return nil
    }
    return canonicalName(for: selectedGroup)
  }

  private func cancelNewGroup() {
    newGroupName = ""
    isAddingNewGroup = false
  }

  /// 연락처에 대소문자만 다르게 저장된 그룹은 저장된 그룹 이름으로 맞춥니다.
  private func canonicalName(for group: String) -> String {
    groups.first { $0.name.compare(group, options: .caseInsensitive) == .orderedSame }?.name ?? group
  }
}
