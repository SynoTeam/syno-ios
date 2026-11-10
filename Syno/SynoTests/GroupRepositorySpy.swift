import Foundation
@testable import Syno

/// 그룹 화면 ViewModel 테스트에서 쓰는 메모리 저장소입니다.
/// 이름 비교는 실제 저장소처럼 대소문자를 무시합니다.
@MainActor
final class GroupRepositorySpy: GroupRepository {
  private(set) var groups: [ContactGroup]
  var shouldFail = false
  private(set) var deletedNames: [String] = []
  private(set) var savedSortOrders: [[String]] = []
  private(set) var createdNames: [String] = []

  init(groups: [ContactGroup]) {
    self.groups = groups
  }

  func fetchGroups() throws -> [ContactGroup] {
    groups.sorted { $0.sortIndex < $1.sortIndex }
  }

  func createGroup(named name: String) throws -> ContactGroup? {
    if shouldFail { throw SpyError.failed }
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return nil
    }
    if let existing = groups.first(where: { $0.name.lowercased() == trimmed.lowercased() }) {
      return existing
    }
    let group = ContactGroup(name: trimmed, sortIndex: (groups.map(\.sortIndex).max() ?? -1) + 1)
    groups.append(group)
    createdNames.append(trimmed)
    return group
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
