import SwiftData

@MainActor
enum PreviewRepositories {
  private static let container: ModelContainer = {
    do {
      return try ModelContainer(
        for: UserProfile.self,
        StoredContact.self,
        StoredNote.self,
        StoredContactEmbedding.self,
        StoredNoteEmbedding.self,
        StoredNoteImageAnalysis.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
    } catch {
      fatalError("Failed to create preview model container: \(error)")
    }
  }()

  static let searchIndex: any SearchIndexing = LocalSearchIndex(
    repository: SwiftDataSearchEmbeddingRepository(modelContainer: container),
    embeddingProvider: NLContextualTextEmbeddingProvider()
  )

  static let noteImageAnalyzer: any NoteImageAnalyzing = VisionNoteImageAnalyzer()

  static let noteImageAnalysis: any NoteImageAnalysisRepository =
    SwiftDataNoteImageAnalysisRepository(modelContainer: container)

  static let contact: any ContactRepository =
    SwiftDataContactRepository(
      modelContext: container.mainContext,
      searchIndex: searchIndex
    )

  static let note: any NoteRepository =
    SwiftDataNoteRepository(
      modelContext: container.mainContext,
      searchIndex: searchIndex
    )

  static let userProfile: any UserProfileRepository =
    SwiftDataUserProfileRepository(modelContext: container.mainContext)
}
