import SwiftData
import SwiftUI

@MainActor
enum PreviewRepositories {
  static let container: ModelContainer = {
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
        StoredNoteVoiceTranscript.self,
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
  static let noteVoiceTranscriber: any NoteVoiceTranscribing = SpeechNoteVoiceTranscriber()
  static let noteVoiceTranscript: any NoteVoiceTranscriptRepository =
    SwiftDataNoteVoiceTranscriptRepository(modelContainer: container)

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

  static let appContainer = AppContainer(
    modelContainer: container,
    contactRepository: contact,
    noteRepository: note,
    userProfileRepository: userProfile,
    searchIndex: searchIndex,
    noteImageAnalyzer: noteImageAnalyzer,
    noteImageAnalysisRepository: noteImageAnalysis,
    linkPreviewFetcher: linkPreviewFetcher,
    noteLinkPreviewRepository: noteLinkPreview,
    labelTranslator: labelTranslator,
    noteVoiceTranscriber: noteVoiceTranscriber,
    noteVoiceTranscriptRepository: noteVoiceTranscript,
    accountResetService: accountReset,
    searchIndexBackfillService: SearchIndexBackfillService(
      modelContext: container.mainContext,
      searchIndex: searchIndex,
      noteImageAnalysisRepository: noteImageAnalysis,
      labelTranslator: labelTranslator
    ),
    groupService: GroupService(modelContext: container.mainContext)
  )
}

extension View {
  /// `@Query`를 쓰는 화면의 프리뷰에 미리보기용 모델 컨테이너를 주입합니다.
  func previewModelContainer() -> some View {
    modelContainer(PreviewRepositories.container)
  }
}
