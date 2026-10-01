import SwiftUI

extension EnvironmentValues {
  @Entry var analytics: any AnalyticsTracking = NoopAnalyticsTracking()
}
