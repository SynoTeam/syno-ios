import CoreData
import Foundation
import Testing
@testable import Syno

/// iCloud 동기화 카드의 상태 표시 규칙과 마지막 동기화 시각 기록 규칙입니다 (#136).
@MainActor
struct CloudSyncSettingsViewModelTests {
  private let defaults: UserDefaults

  init() throws {
    let suiteName = "CloudSyncSettingsViewModelTests-\(UUID().uuidString)"
    defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
  }

  // MARK: - 마지막 동기화 시각 기록

  @Test("동기화 기록이 없으면 마지막 동기화 시각은 없다")
  func historyStartsEmpty() {
    #expect(CloudSyncHistory(defaults: defaults).lastSyncedAt == nil)
  }

  @Test("늦게 도착한 이전 이벤트가 더 최근 시각을 덮어쓰지 않는다")
  func historyKeepsLatestDate() {
    let history = CloudSyncHistory(defaults: defaults)
    let earlier = Date(timeIntervalSince1970: 1_000)
    let later = Date(timeIntervalSince1970: 2_000)

    history.record(later)
    history.record(earlier)

    #expect(CloudSyncHistory(defaults: defaults).lastSyncedAt == later)
  }

  @Test("성공적으로 끝난 가져오기·내보내기만 동기화 시각으로 기록한다", arguments: [
    (NSPersistentCloudKitContainer.EventType.import, true, true, true),
    (.export, true, true, true),
    (.setup, true, true, false),
    (.export, false, true, false),
    (.import, true, false, false),
  ] as [(NSPersistentCloudKitContainer.EventType, Bool, Bool, Bool)])
  func syncedDateRule(
    type: NSPersistentCloudKitContainer.EventType,
    succeeded: Bool,
    hasEnded: Bool,
    isRecorded: Bool
  ) {
    let endDate = Date(timeIntervalSince1970: 3_000)

    let date = CloudSyncService.syncedDate(
      type: type,
      succeeded: succeeded,
      endDate: hasEnded ? endDate : nil
    )

    #expect(date == (isRecorded ? endDate : nil))
  }

  // MARK: - 계정 상태와 토글

  @Test("iCloud 상태를 확인하기 전에는 토글을 막는다")
  func toggleDisabledBeforeRefresh() {
    let viewModel = makeViewModel(accountState: .available)

    #expect(!viewModel.canToggle)
  }

  @Test("iCloud 계정 상태에 따라 토글 사용 여부와 안내 문구가 정해진다", arguments: [
    (CloudAccountState.available, true, nil),
    (.noAccount, false, "iCloud에 로그인하면 동기화를 사용할 수 있습니다. 설정 앱에서 Apple 계정에 로그인해 주세요."),
    (.unavailable, false, "지금은 iCloud를 사용할 수 없습니다. 잠시 후 다시 확인해 주세요."),
  ] as [(CloudAccountState, Bool, String?)])
  func accountStateRule(state: CloudAccountState, canToggle: Bool, message: String?) async {
    let viewModel = makeViewModel(accountState: state)

    await viewModel.refresh()

    #expect(viewModel.canToggle == canToggle)
    #expect(viewModel.accountMessage == message)
  }

  @Test("iCloud에 로그인되어 있지 않으면 토글을 바꿔도 설정이 바뀌지 않는다")
  func toggleIgnoredWithoutAccount() async {
    let viewModel = makeViewModel(accountState: .noAccount)
    await viewModel.refresh()

    viewModel.setSyncEnabled(false)

    #expect(viewModel.isSyncEnabled)
    #expect(CloudSyncPreference(defaults: defaults).isEnabled)
  }

  @Test("동기화를 끄면 설정을 저장하고, 다시 시작하면 꺼진다고 안내한다")
  func turningOffSavesAndAsksRestart() async {
    let viewModel = makeViewModel(accountState: .available)
    await viewModel.refresh()

    viewModel.setSyncEnabled(false)

    #expect(!viewModel.isSyncEnabled)
    #expect(!CloudSyncPreference(defaults: defaults).isEnabled)
    #expect(viewModel.restartMessage == "앱을 다시 시작하면 동기화가 꺼집니다.")
  }

  @Test("꺼진 채로 실행한 뒤 켜면, 다시 시작하면 켜진다고 안내한다")
  func turningOnAsksRestart() async {
    CloudSyncPreference(defaults: defaults).isEnabled = false
    let viewModel = makeViewModel(accountState: .available)
    await viewModel.refresh()

    viewModel.setSyncEnabled(true)

    #expect(viewModel.restartMessage == "앱을 다시 시작하면 동기화가 켜집니다.")
  }

  @Test("실행할 때의 값으로 되돌리면 다시 시작 안내가 사라진다")
  func revertingClearsRestartNotice() async {
    let viewModel = makeViewModel(accountState: .available)
    await viewModel.refresh()

    viewModel.setSyncEnabled(false)
    viewModel.setSyncEnabled(true)

    #expect(viewModel.restartMessage == nil)
  }

  @Test("켜짐과 꺼짐에 따라 설명 문구가 바뀐다", arguments: [
    (true, "노트와 연락처를 iCloud에 저장하고 같은 iCloud 계정을 쓰는 기기와 동기화합니다."),
    (false, "이 기기에만 저장되며 다른 기기와 동기화되지 않습니다. 이미 iCloud에 있는 데이터는 지워지지 않습니다."),
  ])
  func descriptionFollowsToggle(isEnabled: Bool, expected: String) async {
    let viewModel = makeViewModel(accountState: .available)
    await viewModel.refresh()

    viewModel.setSyncEnabled(isEnabled)

    #expect(viewModel.descriptionText == expected)
  }

  @Test("iCloud를 쓸 수 없으면 저장된 설정과 관계없이 꺼짐으로 보이고, 이 기기에만 저장된다고 설명한다", arguments: [
    (CloudAccountState.available, true, "노트와 연락처를 iCloud에 저장하고 같은 iCloud 계정을 쓰는 기기와 동기화합니다."),
    (.noAccount, false, "iCloud를 사용할 수 없어 이 기기에만 저장됩니다."),
    (.unavailable, false, "iCloud를 사용할 수 없어 이 기기에만 저장됩니다."),
  ] as [(CloudAccountState, Bool, String)])
  func displayFollowsAccountState(state: CloudAccountState, isToggleOn: Bool, description: String) async {
    let viewModel = makeViewModel(accountState: state)

    await viewModel.refresh()

    #expect(viewModel.isToggleOn == isToggleOn)
    #expect(viewModel.descriptionText == description)
    // 화면 표시만 바뀌고 저장된 설정은 그대로라, 나중에 로그인하면 원래 설정으로 돌아온다.
    #expect(CloudSyncPreference(defaults: defaults).isEnabled)
    #expect(viewModel.restartMessage == nil)
  }

  // MARK: - 마지막 동기화 표시

  @Test("마지막 동기화 시각 표시", arguments: [
    (nil, "아직 동기화 기록이 없습니다"),
    (Date(timeIntervalSince1970: 1_794_578_700), "2026.11.13 14:05"),
  ] as [(Date?, String)])
  func lastSyncTextRule(date: Date?, expected: String) throws {
    let utc = try #require(TimeZone(secondsFromGMT: 0))

    #expect(CloudSyncSettingsViewModel.lastSyncText(for: date, timeZone: utc) == expected)
  }

  @Test("새로고침하면 그 사이에 기록된 동기화 시각을 다시 읽는다")
  func refreshRereadsLastSync() async {
    let viewModel = makeViewModel(accountState: .available)
    let syncedAt = Date(timeIntervalSince1970: 5_000)

    CloudSyncHistory(defaults: defaults).record(syncedAt)
    await viewModel.refresh()

    #expect(viewModel.lastSyncedAt == syncedAt)
  }

  private func makeViewModel(accountState: CloudAccountState) -> CloudSyncSettingsViewModel {
    CloudSyncSettingsViewModel(
      service: CloudSyncService(
        preference: CloudSyncPreference(defaults: defaults),
        history: CloudSyncHistory(defaults: defaults),
        accountStatusChecker: FixedCloudAccountStatusChecker(state: accountState)
      )
    )
  }
}
