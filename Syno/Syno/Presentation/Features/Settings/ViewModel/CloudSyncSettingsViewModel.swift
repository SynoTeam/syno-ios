import Foundation
import Observation

/// 노트 저장공간 관리의 iCloud 동기화 카드 상태를 담당합니다 (#136).
@MainActor
@Observable
final class CloudSyncSettingsViewModel {
  private let service: CloudSyncService

  private(set) var isSyncEnabled: Bool
  /// nil이면 아직 확인 중입니다.
  private(set) var accountState: CloudAccountState?
  private(set) var lastSyncedAt: Date?
  private(set) var isRefreshing = false

  init(service: CloudSyncService) {
    self.service = service
    isSyncEnabled = service.isEnabled
    lastSyncedAt = service.lastSyncedAt
  }

  /// iCloud를 쓸 수 있다고 확인된 경우에만 토글을 바꿀 수 있습니다.
  var canToggle: Bool {
    accountState == .available
  }

  var accountMessage: String? {
    switch accountState {
    case .noAccount:
      "iCloud에 로그인하면 동기화를 사용할 수 있습니다. 설정 앱에서 Apple 계정에 로그인해 주세요."
    case .unavailable:
      "지금은 iCloud를 사용할 수 없습니다. 잠시 후 다시 확인해 주세요."
    case .available, nil:
      nil
    }
  }

  /// 저장소는 실행할 때 한 번 열리므로, 바꾼 설정은 다시 시작해야 적용됩니다.
  /// 설명 문구는 토글을 따르므로, 다시 시작하기 전까지는 실제 동작이 다르다는 점을 방향과 함께 알립니다.
  var restartMessage: String? {
    guard isSyncEnabled != service.isEnabledAtLaunch else {
      return nil
    }
    return isSyncEnabled
      ? "앱을 다시 시작하면 동기화가 켜집니다."
      : "앱을 다시 시작하면 동기화가 꺼집니다."
  }

  /// iCloud를 쓸 수 없다고 확인된 상태입니다. 확인 중(nil)은 포함하지 않습니다.
  private var isCloudUnavailable: Bool {
    accountState == .noAccount || accountState == .unavailable
  }

  /// 토글에 보이는 값입니다. iCloud를 쓸 수 없으면 실제로 동기화되지 않으므로 꺼짐으로 보입니다.
  /// 저장된 설정은 바꾸지 않아서, 다시 로그인하면 원래 설정으로 돌아옵니다.
  var isToggleOn: Bool {
    isSyncEnabled && !isCloudUnavailable
  }

  var descriptionText: String {
    if isCloudUnavailable {
      "iCloud를 사용할 수 없어 이 기기에만 저장됩니다."
    } else if isSyncEnabled {
      "노트와 연락처를 iCloud에 저장하고 같은 iCloud 계정을 쓰는 기기와 동기화합니다."
    } else {
      "이 기기에만 저장되며 다른 기기와 동기화되지 않습니다. 이미 iCloud에 있는 데이터는 지워지지 않습니다."
    }
  }

  var lastSyncText: String {
    Self.lastSyncText(for: lastSyncedAt)
  }

  /// iCloud 계정 상태와 마지막 동기화 시각을 다시 확인합니다. 동기화를 즉시 실행하지는 않습니다.
  func refresh() async {
    isRefreshing = true
    defer { isRefreshing = false }

    accountState = await service.accountState()
    lastSyncedAt = service.lastSyncedAt
  }

  func setSyncEnabled(_ isEnabled: Bool) {
    guard canToggle else {
      return
    }
    service.setEnabled(isEnabled)
    isSyncEnabled = isEnabled
  }

  static func lastSyncText(for date: Date?, timeZone: TimeZone = .current) -> String {
    guard let date else {
      return "아직 동기화 기록이 없습니다"
    }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.timeZone = timeZone
    formatter.dateFormat = "yyyy.MM.dd HH:mm"
    return formatter.string(from: date)
  }
}
