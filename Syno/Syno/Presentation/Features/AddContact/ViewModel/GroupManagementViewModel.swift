import Foundation
import Observation
// List의 순서 변경 규칙(`move(fromOffsets:toOffset:)`)을 그대로 쓰기 위해 가져옵니다.
import SwiftUI

/// 노트 → 그룹 편집하기 시트의 상태입니다. 그룹 목록, 정렬 방식, 삭제·순서 변경을 다룹니다.
/// 그룹 추가는 연락처 편집의 그룹 선택 시트에서만 합니다.
@MainActor
@Observable
final class GroupManagementViewModel {
  enum SortMode: String, CaseIterable, Identifiable {
    case alphabetical = "가나다순"
    case custom = "사용자 설정 순"

    var id: String { rawValue }
  }

  /// 저장된 순서대로의 그룹입니다.
  private(set) var groups: [ContactGroup] = []
  /// 실패를 알릴 문구입니다. 화면이 토스트로 보여준 뒤 비웁니다.
  var failureMessage: String?

  var sortMode: SortMode {
    didSet {
      userDefaults.set(sortMode.rawValue, forKey: Self.sortModeKey)
    }
  }

  /// 사용자 설정 순일 때만 순서를 바꿀 수 있습니다.
  var canReorder: Bool {
    sortMode == .custom
  }

  var displayedGroups: [ContactGroup] {
    switch sortMode {
    case .custom:
      groups
    case .alphabetical:
      groups.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
  }

  /// 이전 버전 시트가 `@AppStorage`로 쓰던 키를 그대로 써서, 사용자가 고른 정렬 방식이 유지되게 합니다.
  private static let sortModeKey = "GroupManagementSheet.sortMode"

  private let groupRepository: any GroupRepository
  private let userDefaults: UserDefaults

  init(groupRepository: any GroupRepository, userDefaults: UserDefaults = .standard) {
    self.groupRepository = groupRepository
    self.userDefaults = userDefaults
    sortMode = userDefaults.string(forKey: Self.sortModeKey).flatMap(SortMode.init(rawValue:)) ?? .alphabetical
  }

  func load() {
    do {
      groups = try groupRepository.fetchGroups()
    } catch {
      groups = []
    }
  }

  func deleteGroup(named name: String) {
    do {
      try groupRepository.deleteGroup(named: name)
      groups.removeAll { $0.name == name }
    } catch {
      failureMessage = "그룹 삭제에 실패했습니다"
    }
  }

  func moveGroups(from source: IndexSet, to destination: Int) {
    guard canReorder else {
      return
    }

    var names = groups.map(\.name)
    names.move(fromOffsets: source, toOffset: destination)
    do {
      try groupRepository.updateSortOrder(names)
      groups = names.enumerated().map { ContactGroup(name: $1, sortIndex: $0) }
    } catch {
      failureMessage = "그룹 순서 저장에 실패했습니다"
    }
  }
}
