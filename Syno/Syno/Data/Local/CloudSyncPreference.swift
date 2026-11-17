import Foundation

/// iCloud 동기화를 켤지 끌지에 대한 사용자 설정입니다 (#136).
/// 저장소는 앱을 시작할 때 이 값으로 열립니다.
struct CloudSyncPreference {
  static let key = "cloudSyncEnabled"

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  /// 설정한 적이 없으면 켜져 있습니다. 이 기능 전부터 쓰던 사용자는 지금처럼 동기화됩니다.
  /// 개발 중에는 Xcode 실행 인자 `-cloudSyncEnabled NO`로도 끌 수 있습니다(실행 인자가 저장값보다 우선).
  /// 실행 인자는 문자열("NO")로 들어오므로 `as? Bool` 대신 문자열도 읽는 `bool(forKey:)`를 씁니다.
  var isEnabled: Bool {
    get {
      guard defaults.object(forKey: Self.key) != nil else {
        return true
      }
      return defaults.bool(forKey: Self.key)
    }
    nonmutating set { defaults.set(newValue, forKey: Self.key) }
  }
}
