//
//  SynoApp.swift
//  Syno
//
//  Created by 이승진 on 6/27/26.
//

import SwiftUI
import SwiftData

@main
struct SynoApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
    }
    .modelContainer(for: [UserProfile.self, StoredContact.self])
  }
}
