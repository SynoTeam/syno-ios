import Foundation
import SwiftData

/// 앱이 쓰는 저장소와 서비스를 한곳에서 조립해 들고 있는 컨테이너입니다.
/// `SynoApp`, `RootView`, `MainTabView`에서만 사용하고, 각 기능 화면에는 필요한 의존성만 꺼내 전달합니다.
@MainActor
final class AppContainer {
  let modelContainer: ModelContainer
  let contactRepository: any ContactRepository
  let noteRepository: any NoteRepository
  let userProfileRepository: any UserProfileRepository
  let searchIndex: any SearchIndexing
  let noteImageAnalyzer: any NoteImageAnalyzing
  let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  let linkPreviewFetcher: any NoteLinkPreviewFetching
  let noteLinkPreviewRepository: any NoteLinkPreviewRepository
  let labelTranslator: any LabelTranslating
  let noteVoiceTranscriber: any NoteVoiceTranscribing
  let noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository
  let accountResetService: AccountResetService
  let searchIndexBackfillService: SearchIndexBackfillService
  let groupService: GroupService

  init(
    modelContainer: ModelContainer,
    contactRepository: any ContactRepository,
    noteRepository: any NoteRepository,
    userProfileRepository: any UserProfileRepository,
    searchIndex: any SearchIndexing,
    noteImageAnalyzer: any NoteImageAnalyzing,
    noteImageAnalysisRepository: any NoteImageAnalysisRepository,
    linkPreviewFetcher: any NoteLinkPreviewFetching,
    noteLinkPreviewRepository: any NoteLinkPreviewRepository,
    labelTranslator: any LabelTranslating,
    noteVoiceTranscriber: any NoteVoiceTranscribing,
    noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository,
    accountResetService: AccountResetService,
    searchIndexBackfillService: SearchIndexBackfillService,
    groupService: GroupService
  ) {
    self.modelContainer = modelContainer
    self.contactRepository = contactRepository
    self.noteRepository = noteRepository
    self.userProfileRepository = userProfileRepository
    self.searchIndex = searchIndex
    self.noteImageAnalyzer = noteImageAnalyzer
    self.noteImageAnalysisRepository = noteImageAnalysisRepository
    self.linkPreviewFetcher = linkPreviewFetcher
    self.noteLinkPreviewRepository = noteLinkPreviewRepository
    self.labelTranslator = labelTranslator
    self.noteVoiceTranscriber = noteVoiceTranscriber
    self.noteVoiceTranscriptRepository = noteVoiceTranscriptRepository
    self.accountResetService = accountResetService
    self.searchIndexBackfillService = searchIndexBackfillService
    self.groupService = groupService
  }

  /// 앱 시작 시 한 번 실행하는 보정 작업입니다.
  func runStartupTasks() async {
    await searchIndexBackfillService.start()
    try? groupService.backfillGroupsIfNeeded()
  }

  /// 앱이 저장하는 SwiftData 모델 전체입니다. 공유 확장과 같은 목록을 씁니다.
  static let schema = SynoSchema.schema

  /// 실제 저장소(App Group, CloudKit)를 사용하는 운영용 컨테이너를 조립합니다.
  static func live() -> AppContainer {
    guard let appGroupContainerURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.synoteam.Syno"
    ) else {
      fatalError("App Group container unavailable: group.com.synoteam.Syno")
    }
    let configuration = ModelConfiguration(
      schema: schema,
      url: appGroupContainerURL.appendingPathComponent("Syno.sqlite"),
      cloudKitDatabase: .private("iCloud.com.synoteam.Syno")
    )
    return make(configuration: configuration, linkPreviewFetcher: URLSessionLinkPreviewFetcher())
  }

  #if DEBUG
  /// 테스트용 컨테이너입니다. 메모리에만 저장하고 CloudKit과 네트워크를 쓰지 않습니다.
  /// 단위 테스트의 호스트 앱이 운영 저장소를 건드리지 않게 할 때 씁니다.
  static func inMemory() -> AppContainer {
    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: true,
      cloudKitDatabase: .none
    )
    return make(configuration: configuration, linkPreviewFetcher: NoopNoteLinkPreviewFetcher())
  }

  /// UI 테스트용 컨테이너입니다. 메모리 저장소에 고정된 샘플 데이터를 넣어 둡니다.
  static func uiTest() -> AppContainer {
    let container = inMemory()
    UITestFixtureSeeder.seed(into: container.modelContainer.mainContext)
    return container
  }
  #endif

  /// 저장소 설정만 다르게 해서 같은 방식으로 컨테이너를 조립합니다.
  static func make(
    configuration: ModelConfiguration,
    linkPreviewFetcher: any NoteLinkPreviewFetching
  ) -> AppContainer {
    do {
      let container = try ModelContainer(
        for: schema,
        configurations: configuration
      )
      let embeddingRepository = SwiftDataSearchEmbeddingRepository(
        modelContainer: container
      )
      let index = LocalSearchIndex(
        repository: embeddingRepository,
        embeddingProvider: NLContextualTextEmbeddingProvider()
      )
      let imageAnalysisRepository = SwiftDataNoteImageAnalysisRepository(
        modelContainer: container
      )
      let staticLabelDictionary = StaticLabelDictionary()

      return AppContainer(
        modelContainer: container,
        contactRepository: SwiftDataContactRepository(
          modelContext: container.mainContext,
          searchIndex: index
        ),
        noteRepository: SwiftDataNoteRepository(
          modelContext: container.mainContext,
          searchIndex: index
        ),
        userProfileRepository: SwiftDataUserProfileRepository(modelContext: container.mainContext),
        searchIndex: index,
        noteImageAnalyzer: VisionNoteImageAnalyzer(),
        noteImageAnalysisRepository: imageAnalysisRepository,
        linkPreviewFetcher: linkPreviewFetcher,
        noteLinkPreviewRepository: SwiftDataNoteLinkPreviewRepository(modelContainer: container),
        labelTranslator: staticLabelDictionary,
        noteVoiceTranscriber: SpeechNoteVoiceTranscriber(),
        noteVoiceTranscriptRepository: SwiftDataNoteVoiceTranscriptRepository(modelContainer: container),
        accountResetService: AccountResetService(modelContext: container.mainContext),
        searchIndexBackfillService: SearchIndexBackfillService(
          modelContext: container.mainContext,
          searchIndex: index,
          noteImageAnalysisRepository: imageAnalysisRepository,
          labelTranslator: staticLabelDictionary
        ),
        groupService: GroupService(modelContext: container.mainContext)
      )
    } catch {
      fatalError("Failed to create model container: \(error)")
    }
  }
}
