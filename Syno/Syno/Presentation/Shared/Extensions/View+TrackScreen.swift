import SwiftUI

private struct TrackScreenModifier: ViewModifier {
  @Environment(\.analytics) private var analytics
  let screenName: String

  func body(content: Content) -> some View {
    content.onAppear {
      analytics.track(AnalyticsEvent.screenViewed, properties: [AnalyticsEvent.Property.screenName: screenName])
    }
  }
}

extension View {
  /// 화면에 나타날 때마다 `Screen Viewed` 이벤트를 남깁니다.
  func trackScreen(_ screenName: String) -> some View {
    modifier(TrackScreenModifier(screenName: screenName))
  }
}
