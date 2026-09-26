import Foundation

/// 화면 방문/주요 기능 사용 이벤트를 기록하는 공통 인터페이스입니다.
/// 연락처 이름, 메모 내용 등 실제 개인 콘텐츠는 절대 이벤트 속성에 포함하지 않습니다.
protocol AnalyticsTracking {
  func track(_ event: String, properties: [String: Any]?)
  func resetIdentity()
}

extension AnalyticsTracking {
  func track(_ event: String) {
    track(event, properties: nil)
  }
}

/// 프리뷰/테스트에서 사용하는, 아무 동작도 하지 않는 트래커입니다.
struct NoopAnalyticsTracking: AnalyticsTracking {
  func track(_ event: String, properties: [String: Any]?) {}
  func resetIdentity() {}
}
