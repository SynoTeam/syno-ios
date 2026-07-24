import SwiftData
import XCTest
@testable import Syno

final class SearchViewModelImageKeywordTests: XCTestCase {
  @MainActor
  func testImageLabelsMatchInKoreanAndPreserveUnmappedEnglish() async throws {
    let container = try ModelContainer(
      for: StoredContact.self,
      StoredNote.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let noteId = UUID()
    container.mainContext.insert(
      StoredNote(
        id: noteId,
        contactId: nil,
        contactName: "사진 메모",
        content: "사진",
        imageData: Data([0x01]),
        profileImageData: nil,
        isFavorite: false
      )
    )
    try container.mainContext.save()
    let defaults = try XCTUnwrap(
      UserDefaults(suiteName: "SearchViewModelImageKeywordTests")
    )
    defaults.removePersistentDomain(forName: "SearchViewModelImageKeywordTests")
    let viewModel = SearchViewModel(
      modelContext: container.mainContext,
      searchIndex: EmptySearchIndex(),
      noteImageAnalysisRepository: ImageAnalysisRepositoryStub(
        analyses: [
          noteId: NoteImageAnalysisResult(
            labels: ["animal", "cat", "unmapped_label"],
            ocrText: ""
          )
        ]
      ),
      labelTranslator: StaticLabelDictionary(
        translations: ["cat": "고양이"]
      ),
      userDefaults: defaults
    )

    viewModel.updateQuery("고양이")
    try await Task.sleep(for: .milliseconds(500))

    XCTAssertFalse(viewModel.isSearching)
    XCTAssertEqual(viewModel.filteredResults.count, 1)
    XCTAssertEqual(viewModel.filteredResults.first?.category, .notes)

    viewModel.updateQuery("unmapped_label")
    try await Task.sleep(for: .milliseconds(500))

    XCTAssertEqual(viewModel.filteredResults.count, 1)
  }
}

@MainActor
private final class EmptySearchIndex: SearchIndexing {
  func index(_ document: SearchDocument) async {}
  func backfill(_ documents: [SearchDocument], batchSize: Int) async {}
  func remove(_ key: SearchDocumentKey) async {}

  func scores(
    for query: String,
    documents: [SearchDocument]
  ) async -> [SearchDocumentKey: Double] {
    [:]
  }
}

private struct ImageAnalysisRepositoryStub: NoteImageAnalysisRepository {
  let analyses: [Note.ID: NoteImageAnalysisResult]

  func fetch(noteId: Note.ID) async throws -> NoteImageAnalysisResult? {
    analyses[noteId]
  }

  func fetchAll() async throws -> [Note.ID: NoteImageAnalysisResult] {
    analyses
  }

  func save(
    noteId: Note.ID,
    result: NoteImageAnalysisResult,
    analyzedAt: Date
  ) async throws {}
}
