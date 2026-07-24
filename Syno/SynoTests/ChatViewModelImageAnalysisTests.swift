import UIKit
import XCTest
@testable import Syno

final class ChatViewModelImageAnalysisTests: XCTestCase {
  @MainActor
  func testImageAnalysisFailureDoesNotUndoSavedImageNote() async throws {
    let noteRepository = NoteRepositorySpy()
    let analysisRepository = ImageAnalysisRepositorySpy()
    let viewModel = ChatViewModel(
      contact: Contact(name: "홍길동", role: "", company: ""),
      repository: noteRepository,
      imageAnalyzer: FailingImageAnalyzer(),
      imageAnalysisRepository: analysisRepository
    )
    let imageData = try XCTUnwrap(
      UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        .image { context in
          UIColor.red.setFill()
          context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        .jpegData(compressionQuality: 1)
    )

    await viewModel.sendImageData(imageData)

    XCTAssertEqual(noteRepository.savedNotes.count, 1)
    XCTAssertEqual(noteRepository.savedNotes.first?.content, "사진")
    XCTAssertNotNil(noteRepository.savedNotes.first?.imageData)
    XCTAssertEqual(viewModel.messages.count, 1)
    XCTAssertNil(viewModel.persistenceError)
    let analysisSaveCount = await analysisRepository.saveCount
    XCTAssertEqual(analysisSaveCount, 0)
  }
}

@MainActor
private final class NoteRepositorySpy: NoteRepository {
  private(set) var savedNotes: [Note] = []

  func fetch(contactId: UUID?) throws -> [Note] {
    savedNotes.filter { $0.contactId == contactId }
  }

  func save(_ note: Note) throws {
    savedNotes.append(note)
  }

  func delete(id: Note.ID) throws {
    savedNotes.removeAll { $0.id == id }
  }
}

private struct FailingImageAnalyzer: NoteImageAnalyzing {
  func analyze(imageData: Data) async throws -> NoteImageAnalysisResult {
    throw TestError.analysisFailed
  }
}

private actor ImageAnalysisRepositorySpy: NoteImageAnalysisRepository {
  private(set) var saveCount = 0

  func fetch(noteId: Note.ID) -> NoteImageAnalysisResult? {
    nil
  }

  func fetchAll() -> [Note.ID: NoteImageAnalysisResult] {
    [:]
  }

  func save(
    noteId: Note.ID,
    result: NoteImageAnalysisResult,
    analyzedAt: Date
  ) {
    saveCount += 1
  }
}

private enum TestError: Error {
  case analysisFailed
}
