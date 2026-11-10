import Foundation

/// 연락처 그룹을 읽고 정리하는 저장소 경계입니다.
@MainActor
protocol GroupRepository {
  /// 저장된 그룹을 사용자 지정 순서대로 반환합니다.
  func fetchGroups() throws -> [ContactGroup]
  /// 그룹을 삭제하고, 그 그룹을 쓰던 연락처의 그룹 값을 비웁니다.
  func deleteGroup(named name: String) throws
  /// 전달한 이름 순서를 사용자 지정 순서로 저장합니다.
  func updateSortOrder(_ names: [String]) throws
}
