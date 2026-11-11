import Foundation

/// 연락처 그룹을 읽고 정리하는 저장소 경계입니다.
@MainActor
protocol GroupRepository {
  /// 저장된 그룹을 사용자 지정 순서대로 반환합니다.
  func fetchGroups() throws -> [ContactGroup]
  /// 앞뒤 공백을 뺀 이름으로 그룹을 만들어 맨 뒤에 둡니다.
  /// 대소문자만 다른 그룹이 이미 있으면 새로 만들지 않고 그 그룹을, 이름이 비어 있으면 nil을 반환합니다.
  func createGroup(named name: String) throws -> ContactGroup?
  /// 그룹을 삭제하고, 그 그룹을 쓰던 연락처의 그룹 값을 비웁니다.
  func deleteGroup(named name: String) throws
  /// 전달한 이름 순서를 사용자 지정 순서로 저장합니다.
  func updateSortOrder(_ names: [String]) throws
}
