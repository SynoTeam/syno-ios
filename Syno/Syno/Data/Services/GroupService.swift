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
}

/// 그룹은 이름(대소문자 무시)으로 구분합니다. 기기마다 백필한 그룹이 CloudKit으로 합쳐지면
/// 같은 이름의 행이 여러 개 생길 수 있어서, 같은 이름의 행은 모두 하나의 그룹으로 다룹니다.
extension GroupService: GroupRepository {
  func createGroup(named value: String) throws -> ContactGroup? {
    let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else {
      return nil
    }

    let groups = try storedGroupsInSortOrder()
    if let existing = groups.first(where: { Self.groupKey($0.name) == Self.groupKey(name) }) {
      return ContactGroup(name: existing.name, sortIndex: existing.sortIndex)
    }

    let nextSortIndex = (groups.map(\.sortIndex).max() ?? -1) + 1
    modelContext.insert(StoredGroup(name: name, sortIndex: nextSortIndex))
    do {
      try modelContext.save()
      return ContactGroup(name: name, sortIndex: nextSortIndex)
    } catch {
      modelContext.rollback()
      throw error
    }
  }

  func fetchGroups() throws -> [ContactGroup] {
    var seenKeys: Set<String> = []
    return try storedGroupsInSortOrder().compactMap { group in
      guard seenKeys.insert(Self.groupKey(group.name)).inserted else {
        return nil
      }
      return ContactGroup(name: group.name, sortIndex: group.sortIndex)
    }
  }

  func deleteGroup(named name: String) throws {
    let key = Self.groupKey(name)
    // 조회를 모두 끝낸 뒤에 변경한다. 중간에 조회가 실패해도 컨텍스트에 반쯤 바뀐 상태가 남지 않게 하기 위해서다.
    let rows = try storedGroupsInSortOrder().filter { Self.groupKey($0.name) == key }
    guard !rows.isEmpty else {
      return
    }
    let contacts = try modelContext.fetch(FetchDescriptor<StoredContact>())

    for contact in contacts where Self.groupKey(contact.group) == key {
      contact.group = ""
    }
    for row in rows {
      modelContext.delete(row)
    }

    do {
      try modelContext.save()
    } catch {
      modelContext.rollback()
      throw error
    }
  }

  func updateSortOrder(_ names: [String]) throws {
    let rowsByKey = Dictionary(grouping: try storedGroupsInSortOrder()) { Self.groupKey($0.name) }
    for (index, name) in names.enumerated() {
      let rows = rowsByKey[Self.groupKey(name)] ?? []
      // 중복 행에 같은 순서를 주면 읽을 때 대표 이름이 매번 달라질 수 있어서,
      // 화면에 보이던 이름의 행 하나만 남기고 나머지는 지운다. 연락처는 이름으로 그룹을 참조하므로 영향이 없다.
      guard let kept = rows.first(where: { $0.name == name }) ?? rows.first else {
        continue
      }
      kept.sortIndex = index
      for duplicate in rows where duplicate !== kept {
        modelContext.delete(duplicate)
      }
    }

    do {
      try modelContext.save()
    } catch {
      modelContext.rollback()
      throw error
    }
  }

  private func storedGroupsInSortOrder() throws -> [StoredGroup] {
    try modelContext.fetch(FetchDescriptor<StoredGroup>(sortBy: [SortDescriptor(\.sortIndex)]))
  }

  /// 대소문자만 다른 이름을 같은 그룹으로 보기 위한 비교 키입니다.
  private static func groupKey(_ name: String) -> String {
    name.lowercased()
  }
}
