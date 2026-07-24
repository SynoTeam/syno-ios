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
}
