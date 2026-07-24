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
  private let searchIndex: any SearchIndexing
  private let searchIndexBackfillService: SearchIndexBackfillService
  private let noteImageAnalyzer: any NoteImageAnalyzing
  private let noteImageAnalysisRepository: any NoteImageAnalysisRepository

  init() {
    do {
      let container = try ModelContainer(
        for: UserProfile.self,
        StoredContact.self,
        StoredNote.self,
        StoredContactEmbedding.self,
        StoredNoteEmbedding.self,
        StoredNoteImageAnalysis.self
      )
      modelContainer = container
      let embeddingRepository = SwiftDataSearchEmbeddingRepository(
        modelContainer: container
      )
      let index = LocalSearchIndex(
        repository: embeddingRepository,
        embeddingProvider: NLContextualTextEmbeddingProvider()
      )
      searchIndex = index
      noteImageAnalyzer = VisionNoteImageAnalyzer()
      let imageAnalysisRepository = SwiftDataNoteImageAnalysisRepository(
        modelContainer: container
      )
      noteImageAnalysisRepository = imageAnalysisRepository
      searchIndexBackfillService = SearchIndexBackfillService(
        modelContext: container.mainContext,
        searchIndex: index,
        noteImageAnalysisRepository: imageAnalysisRepository
      )
      contactRepository = SwiftDataContactRepository(
        modelContext: container.mainContext,
        searchIndex: index
      )
      noteRepository = SwiftDataNoteRepository(
        modelContext: container.mainContext,
        searchIndex: index
      )
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
        userProfileRepository: userProfileRepository,
        searchIndex: searchIndex,
        noteImageAnalyzer: noteImageAnalyzer,
        noteImageAnalysisRepository: noteImageAnalysisRepository
      )
      .task {
        await searchIndexBackfillService.start()
      }
    }
    .modelContainer(modelContainer)
  }
}
