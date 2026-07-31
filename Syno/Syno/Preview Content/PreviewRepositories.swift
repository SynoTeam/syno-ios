import SwiftData

@MainActor
enum PreviewRepositories {
  private static let container: ModelContainer = {
    do {
      return try ModelContainer(
        for: UserProfile.self,
        StoredContact.self,
        StoredGroup.self,
        StoredNote.self,
        StoredContactEmbedding.self,
        StoredNoteEmbedding.self,
        StoredNoteImageAnalysis.self,
        StoredNoteLinkPreview.self,
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
  static let labelTranslator: any LabelTranslating = StaticLabelDictionary()

  static let noteImageAnalysis: any NoteImageAnalysisRepository =
    SwiftDataNoteImageAnalysisRepository(modelContainer: container)

  static let linkPreviewFetcher: any NoteLinkPreviewFetching = URLSessionLinkPreviewFetcher()
  static let noteLinkPreview: any NoteLinkPreviewRepository =
    SwiftDataNoteLinkPreviewRepository(modelContainer: container)

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

  static let accountReset = AccountResetService(modelContext: container.mainContext)
}
