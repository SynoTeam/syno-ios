import Foundation

/// 연락처를 묶는 그룹입니다. 이름은 대소문자를 무시하고 중복되지 않으므로 이름으로 구분합니다.
/// SwiftUI의 `Group`과 이름이 겹치지 않도록 `ContactGroup`이라고 부릅니다.
struct ContactGroup: Identifiable, Equatable, Hashable {
  let name: String
  /// 사용자가 정한 순서입니다. 작을수록 앞입니다.
  let sortIndex: Int

  var id: String { name }
}
