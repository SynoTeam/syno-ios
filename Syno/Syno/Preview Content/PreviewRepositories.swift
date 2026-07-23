import SwiftData

@MainActor
enum PreviewRepositories {
  private static let container: ModelContainer = {
    do {
      return try ModelContainer(
        for: UserProfile.self,
        StoredContact.self,
        StoredNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
    } catch {
      fatalError("Failed to create preview model container: \(error)")
    }
  }()

  static let contact: any ContactRepository =
    SwiftDataContactRepository(modelContext: container.mainContext)

  static let note: any NoteRepository =
    SwiftDataNoteRepository(modelContext: container.mainContext)

  static let userProfile: any UserProfileRepository =
    SwiftDataUserProfileRepository(modelContext: container.mainContext)
}
