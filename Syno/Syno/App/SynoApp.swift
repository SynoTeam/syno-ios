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
  private let modelContainer: ModelContainer
  private let contactRepository: any ContactRepository
  private let noteRepository: any NoteRepository
  private let userProfileRepository: any UserProfileRepository

  init() {
    do {
      let container = try ModelContainer(
        for: UserProfile.self,
        StoredContact.self,
        StoredNote.self
      )
      modelContainer = container
      contactRepository = SwiftDataContactRepository(modelContext: container.mainContext)
      noteRepository = SwiftDataNoteRepository(modelContext: container.mainContext)
      userProfileRepository = SwiftDataUserProfileRepository(modelContext: container.mainContext)
    } catch {
      fatalError("Failed to create model container: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView(
        contactRepository: contactRepository,
        noteRepository: noteRepository,
        userProfileRepository: userProfileRepository
      )
    }
    .modelContainer(modelContainer)
  }
}
