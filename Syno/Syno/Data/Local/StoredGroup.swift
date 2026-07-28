import SwiftData

/// 연락처 그룹의 이름과 사용자가 지정한 표시 순서를 저장합니다.
@Model
final class StoredGroup {
  var name: String = ""
  var sortIndex: Int = 0

  init(name: String, sortIndex: Int) {
    self.name = name
    self.sortIndex = sortIndex
  }
}
