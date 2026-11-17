import Foundation

/// 마지막으로 iCloud 동기화(가져오기·내보내기)가 끝난 시각을 기기에 기록합니다 (#136).
/// SwiftData는 동기화 시각을 알려 주는 API가 없어서, 동기화 이벤트를 받을 때마다 여기에 남깁니다.
struct CloudSyncHistory {
  static let key = "cloudSyncLastSyncedAt"

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  var lastSyncedAt: Date? {
    defaults.object(forKey: Self.key) as? Date
  }

  /// 이벤트 알림은 순서대로 오지 않을 수 있으므로, 이미 기록된 시각보다 늦을 때만 바꿉니다.
  func record(_ date: Date) {
    if let lastSyncedAt, lastSyncedAt >= date {
      return
    }
    defaults.set(date, forKey: Self.key)
  }
}
