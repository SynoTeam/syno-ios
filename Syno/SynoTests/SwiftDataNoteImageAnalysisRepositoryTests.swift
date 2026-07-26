import SwiftData
import XCTest
@testable import Syno

final class SwiftDataNoteImageAnalysisRepositoryTests: XCTestCase {
  @MainActor
  func testSaveCanBeReadByNoteIdAndBulkFetch() async throws {
    let container = try ModelContainer(
      for: StoredNoteImageAnalysis.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let repository = SwiftDataNoteImageAnalysisRepository(
      modelContainer: container
    )
    let noteId = UUID()
    let result = NoteImageAnalysisResult(
      labels: ["coffee", "cup"],
      ocrText: "회의 자료"
    )

    try await repository.save(
      noteId: noteId,
      result: result,
      analyzedAt: Date(timeIntervalSince1970: 100)
    )

    let fetched = try await repository.fetch(noteId: noteId)
    let all = try await repository.fetchAll()
    XCTAssertEqual(fetched, result)
    XCTAssertEqual(all[noteId], result)
  }

  @MainActor
  func testSaveUpdatesExistingAnalysisWithoutCreatingDuplicate() async throws {
    let container = try ModelContainer(
      for: StoredNoteImageAnalysis.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let repository = SwiftDataNoteImageAnalysisRepository(
      modelContainer: container
    )
    let noteId = UUID()

    try await repository.save(
      noteId: noteId,
      result: NoteImageAnalysisResult(labels: ["cat"], ocrText: "")
    )
    try await repository.save(
      noteId: noteId,
      result: NoteImageAnalysisResult(labels: ["dog"], ocrText: "수정됨")
    )

    let storedAnalyses = try container.mainContext.fetch(
      FetchDescriptor<StoredNoteImageAnalysis>()
    )
    XCTAssertEqual(storedAnalyses.count, 1)
    XCTAssertEqual(storedAnalyses.first?.labels, ["dog"])
    XCTAssertEqual(storedAnalyses.first?.ocrText, "수정됨")
  }
}
