import Foundation
import SwiftData

/// 연락처 그룹의 백필 및 변경을 담당하는 SwiftData 서비스입니다.
@MainActor
final class GroupService {
  private static let backfillCompletedKey = "StoredGroup.backfillCompleted"
  private let modelContext: ModelContext
  private let userDefaults: UserDefaults

  init(
    modelContext: ModelContext,
    userDefaults: UserDefaults = .standard
  ) {
    self.modelContext = modelContext
    self.userDefaults = userDefaults
  }

  /// 기존 연락처에 저장된 그룹명을 최초 한 번 `StoredGroup`으로 옮깁니다.
  func backfillGroupsIfNeeded() throws {
    guard !userDefaults.bool(forKey: Self.backfillCompletedKey) else {
      return
    }

    let existingGroups = try modelContext.fetch(FetchDescriptor<StoredGroup>())
    guard existingGroups.isEmpty else {
      userDefaults.set(true, forKey: Self.backfillCompletedKey)
      return
    }

    let contacts = try modelContext.fetch(FetchDescriptor<StoredContact>())
    let names = GroupOptions.merged(
      existingGroups: contacts.map(\.group),
      draftGroup: ""
    )

    for (index, name) in names.enumerated() {
      modelContext.insert(StoredGroup(name: name, sortIndex: index))
    }

    if !names.isEmpty {
      try modelContext.save()
    }
    userDefaults.set(true, forKey: Self.backfillCompletedKey)
  }

  /// 새 그룹을 만들고, 대소문자만 다른 기존 그룹이 있으면 그 그룹을 반환합니다.
  func createGroup(named value: String) throws -> StoredGroup? {
    let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else {
      return nil
    }

    let groups = try modelContext.fetch(FetchDescriptor<StoredGroup>())
    if let existing = groups.first(where: {
      $0.name.compare(name, options: .caseInsensitive) == .orderedSame
    }) {
      return existing
    }

    let nextSortIndex = (groups.map(\.sortIndex).max() ?? -1) + 1
    let group = StoredGroup(name: name, sortIndex: nextSortIndex)
    modelContext.insert(group)
    do {
      try modelContext.save()
      return group
    } catch {
      modelContext.rollback()
      throw error
    }
  }

  /// 그룹을 삭제하고 해당 그룹을 사용하던 연락처의 그룹 값을 비웁니다.
  func deleteGroup(_ group: StoredGroup) throws {
    let groupName = group.name
    let contacts = try modelContext.fetch(FetchDescriptor<StoredContact>())

    for contact in contacts where contact.group.compare(groupName, options: .caseInsensitive) == .orderedSame {
      contact.group = ""
    }

    modelContext.delete(group)
    do {
      try modelContext.save()
    } catch {
      modelContext.rollback()
      throw error
    }
  }

  /// 전달된 순서를 사용자 지정 순서로 저장합니다.
  func updateSortIndexes(for groups: [StoredGroup]) throws {
    for (index, group) in groups.enumerated() {
      group.sortIndex = index
    }

    do {
      try modelContext.save()
    } catch {
      modelContext.rollback()
      throw error
    }
  }
}
