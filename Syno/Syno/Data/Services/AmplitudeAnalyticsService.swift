import AmplitudeUnified
import Foundation

/// Amplitude SDK를 감싸는 트래킹 구현체입니다.
final class AmplitudeAnalyticsService: AnalyticsTracking {
  private let amplitude: Amplitude

  init(apiKey: String) {
    let trackingOptions = TrackingOptions()
      .disableTrackVersionName()
      .disableTrackOsName()
      .disableTrackOsVersion()
      .disableTrackDeviceManufacturer()
      .disableTrackDeviceModel()
      .disableTrackCarrier()
      .disableTrackIpAddress()
      .disableTrackCountry()
      .disableTrackCity()
      .disableTrackDMA()
      .disableTrackIDFV()
      .disableTrackLanguage()
      .disableTrackRegion()
      .disableTrackPlatform()

    // Session Replay는 화면을 녹화해서 연락처 이름/메모 내용 같은 민감한 콘텐츠가 그대로 노출될
    // 수 있어, 원격 설정으로도 켜지지 않도록 sampleRate 0 + enableRemoteConfig false로 고정합니다.
    amplitude = Amplitude(
      apiKey: apiKey,
      analyticsConfig: AnalyticsConfig(
        trackingOptions: trackingOptions,
        autocapture: AutocaptureOptions(rawValue: 0),
        enableAutoCaptureRemoteConfig: false
      ),
      sessionReplayConfig: SessionReplayPlugin.Config(sampleRate: 0, enableRemoteConfig: false),
      logger: ConsoleLogger(logLevel: Self.logLevel)
    )
  }

  #if DEBUG
  private static let logLevel = LogLevelEnum.debug.rawValue
  #else
  private static let logLevel = LogLevelEnum.off.rawValue
  #endif

  func track(_ event: String, properties: [String: Any]?) {
    amplitude.track(eventType: event, eventProperties: properties)
  }

  func resetIdentity() {
    amplitude.reset()
  }
}
