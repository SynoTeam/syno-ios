import CloudKit
import CoreData
import Foundation

/// 이 기기의 iCloud 계정 상태입니다.
enum CloudAccountState: Equatable {
  case available
  case noAccount
  /// 제한, 일시적 사용 불가, 확인 실패를 묶습니다. 사용자가 할 수 있는 일이 "잠시 후 다시 확인"으로 같기 때문입니다.
  case unavailable
}

/// iCloud 계정 상태를 확인합니다. 테스트에서는 고정된 상태로 바꿔 끼웁니다.
protocol CloudAccountStatusChecking {
  func accountState() async -> CloudAccountState
}

struct CloudKitAccountStatusChecker: CloudAccountStatusChecking {
  let containerIdentifier: String

  func accountState() async -> CloudAccountState {
    do {
      switch try await CKContainer(identifier: containerIdentifier).accountStatus() {
      case .available:
        return .available
      case .noAccount:
        return .noAccount
      default:
        return .unavailable
      }
    } catch {
      return .unavailable
    }
  }
}

/// 테스트, UI 테스트, 프리뷰에서 항상 같은 계정 상태를 돌려줍니다. CloudKit을 호출하지 않습니다.
struct FixedCloudAccountStatusChecker: CloudAccountStatusChecking {
  let state: CloudAccountState

  func accountState() async -> CloudAccountState {
    state
  }
}

/// iCloud 동기화 설정, 계정 상태, 마지막 동기화 시각을 다룹니다 (#136).
@MainActor
final class CloudSyncService {
  static let containerIdentifier = "iCloud.com.synoteam.Syno"

  /// 앱을 실행할 때 저장소를 연 설정값입니다. 설정을 바꿔도 다음 실행 전까지는 이 값으로 동작합니다.
  let isEnabledAtLaunch: Bool

  private let preference: CloudSyncPreference
  private let history: CloudSyncHistory
  private let accountStatusChecker: any CloudAccountStatusChecking
  private var syncEventObserver: (any NSObjectProtocol)?

  init(
    preference: CloudSyncPreference,
    history: CloudSyncHistory,
    accountStatusChecker: any CloudAccountStatusChecking
  ) {
    self.preference = preference
    self.history = history
    self.accountStatusChecker = accountStatusChecker
    isEnabledAtLaunch = preference.isEnabled
  }

  var isEnabled: Bool {
    preference.isEnabled
  }

  /// 다음 실행부터 적용됩니다. 실행 중에 저장소를 바꿔 열지 않습니다.
  func setEnabled(_ isEnabled: Bool) {
    preference.isEnabled = isEnabled
  }

  var lastSyncedAt: Date? {
    history.lastSyncedAt
  }

  func accountState() async -> CloudAccountState {
    await accountStatusChecker.accountState()
  }

  /// CloudKit 동기화 이벤트를 받아 마지막 동기화 시각을 기록하기 시작합니다. 동기화가 켜진 운영 저장소에서만 부릅니다.
  func startRecordingSyncEvents() {
    guard syncEventObserver == nil else {
      return
    }
    let history = history
    syncEventObserver = NotificationCenter.default.addObserver(
      forName: NSPersistentCloudKitContainer.eventChangedNotification,
      object: nil,
      queue: .main
    ) { notification in
      guard
        let event = notification.userInfo?[
          NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        ] as? NSPersistentCloudKitContainer.Event,
        let date = Self.syncedDate(type: event.type, succeeded: event.succeeded, endDate: event.endDate)
      else {
        return
      }
      history.record(date)
    }
  }

  /// 동기화 이벤트 하나가 마지막 동기화 시각으로 기록할 만한지 판단합니다.
  /// 저장소 준비(setup)는 데이터를 주고받은 것이 아니므로 제외하고, 끝나지 않았거나 실패한 이벤트도 제외합니다.
  nonisolated static func syncedDate(
    type: NSPersistentCloudKitContainer.EventType,
    succeeded: Bool,
    endDate: Date?
  ) -> Date? {
    guard type == .import || type == .export, succeeded else {
      return nil
    }
    return endDate
  }
}
