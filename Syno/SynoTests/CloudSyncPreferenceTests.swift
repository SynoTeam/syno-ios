import Foundation
import SwiftData
import Testing
@testable import Syno

/// iCloud 동기화 켜기/끄기 설정과, 설정에 따른 저장소 구성 규칙입니다 (#136).
@MainActor
struct CloudSyncPreferenceTests {
  private let defaults: UserDefaults

  init() throws {
    let suiteName = "CloudSyncPreferenceTests-\(UUID().uuidString)"
    defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
  }

  @Test("설정한 적이 없으면 동기화는 켜져 있다 (기존 사용자의 동작 유지)")
  func defaultsToEnabled() {
    #expect(CloudSyncPreference(defaults: defaults).isEnabled)
  }

  @Test("끄거나 켠 값을 저장하고 다시 읽는다", arguments: [false, true])
  func storesValue(isEnabled: Bool) {
    var preference = CloudSyncPreference(defaults: defaults)
    preference.isEnabled = isEnabled

    #expect(CloudSyncPreference(defaults: defaults).isEnabled == isEnabled)
  }

  @Test("동기화가 켜져 있으면 앱의 iCloud 컨테이너로, 꺼져 있으면 iCloud 없이 저장소를 연다", arguments: [
    (true, "iCloud.com.synoteam.Syno"),
    (false, nil),
  ] as [(Bool, String?)])
  func storeConfigurationFollowsPreference(isEnabled: Bool, expectedContainer: String?) {
    let configuration = AppContainer.liveConfiguration(
      storeURL: URL(fileURLWithPath: "/tmp/CloudSyncPreferenceTests.sqlite"),
      isCloudSyncEnabled: isEnabled
    )

    #expect(configuration.cloudKitContainerIdentifier == expectedContainer)
  }
}
