//
//  SynoApp.swift
//  Syno
//
//  Created by 이승진 on 6/27/26.
//

import SwiftData
import SwiftUI

@main
struct SynoApp: App {
  private static let amplitudeAPIKey: String = {
    let environmentValue = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY"]
    let bundleValue = Bundle.main.object(forInfoDictionaryKey: "AmplitudeAPIKey") as? String
    return [environmentValue, bundleValue]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .first { !$0.isEmpty } ?? ""
  }()

  private let container: AppContainer
  private let analytics: any AnalyticsTracking

  init() {
    container = AppContainer.live()
    if Self.amplitudeAPIKey.isEmpty {
      analytics = NoopAnalyticsTracking()
    } else {
      analytics = AmplitudeAnalyticsService(apiKey: Self.amplitudeAPIKey)
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView(container: container)
        .task {
          await container.runStartupTasks()
        }
        .preferredColorScheme(.light)
        .environment(\.analytics, analytics)
    }
    .modelContainer(container.modelContainer)
  }
}
