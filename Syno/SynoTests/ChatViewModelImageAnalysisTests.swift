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
      imageAnalysisRepository: analysisRepository,
      labelTranslator: StaticLabelDictionary(translations: [:])
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

  @MainActor
  func testMessageSearchIncludesCachedImageLabelsAndOCR() async throws {
    let contact = Contact(name: "홍길동", role: "", company: "")
    let note = Note(
      contactId: contact.id,
      contactName: contact.name,
      content: "사진",
      imageData: Data([0x01])
    )
    let noteRepository = NoteRepositorySpy()
    try noteRepository.save(note)
    let analysisRepository = ImageAnalysisRepositorySpy(
      analyses: [
        note.id: NoteImageAnalysisResult(
          labels: ["animal", "cat", "feline"],
          ocrText: "INVOICE 2026"
        )
      ]
    )
    let viewModel = ChatViewModel(
      contact: contact,
      repository: noteRepository,
      imageAnalyzer: FailingImageAnalyzer(),
      imageAnalysisRepository: analysisRepository,
      labelTranslator: StaticLabelDictionary(
        translations: ["cat": "고양이"]
      )
    )

    await viewModel.loadMessages()
    viewModel.messageSearchText = "cat"

    XCTAssertEqual(viewModel.messageSearchResults.map(\.id), [note.id])
    viewModel.messageSearchText = "고양이"
    XCTAssertEqual(viewModel.messageSearchResults.map(\.id), [note.id])
    viewModel.messageSearchText = "invoice"
    XCTAssertEqual(viewModel.messageSearchResults.map(\.id), [note.id])
    viewModel.messageSearchText = "냉장고"
    XCTAssertTrue(viewModel.messageSearchResults.isEmpty)
  }

  @MainActor
  func testMessageSectionsGroupsMessagesByCalendarDayInChronologicalOrder() async throws {
    let contact = Contact(name: "홍길동", role: "", company: "")
    let calendar = Calendar(identifier: .gregorian)
    let firstDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 9)))
    let secondDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 18)))
    let thirdDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 9)))
    let noteRepository = NoteRepositorySpy()
    try noteRepository.save(Note(contactId: contact.id, contactName: contact.name, content: "저녁", createdAt: secondDate))
    try noteRepository.save(Note(contactId: contact.id, contactName: contact.name, content: "다음 날", createdAt: thirdDate))
    try noteRepository.save(Note(contactId: contact.id, contactName: contact.name, content: "아침", createdAt: firstDate))
    let viewModel = ChatViewModel(
      contact: contact,
      repository: noteRepository,
      imageAnalyzer: FailingImageAnalyzer(),
      imageAnalysisRepository: ImageAnalysisRepositorySpy(),
      labelTranslator: StaticLabelDictionary(translations: [:])
    )

    await viewModel.loadMessages()

    XCTAssertEqual(viewModel.messageSections.count, 2)
    XCTAssertEqual(viewModel.messageSections.first?.messages.map(\.content), ["아침", "저녁"])
    XCTAssertEqual(viewModel.messageSections.last?.messages.map(\.content), ["다음 날"])
    XCTAssertEqual(viewModel.messageSections.first?.title, "10월 15일 (목)")
  }

  @MainActor
  func testFailedMessageRemainsInlineAndCanBeRetried() async throws {
    let contact = Contact(name: "홍길동", role: "", company: "")
    let noteRepository = RetriableNoteRepositorySpy(shouldFailSaving: true)
    let viewModel = ChatViewModel(
      contact: contact,
      repository: noteRepository,
      imageAnalyzer: FailingImageAnalyzer(),
      imageAnalysisRepository: ImageAnalysisRepositorySpy(),
      labelTranslator: StaticLabelDictionary(translations: [:])
    )
    viewModel.messageText = "전송 실패 메시지"

    viewModel.sendMessage()
    await Task.yield()

    XCTAssertEqual(viewModel.messages.count, 0)
    XCTAssertEqual(viewModel.pendingMessages.count, 1)
    XCTAssertEqual(viewModel.pendingMessages.first?.note.content, "전송 실패 메시지")
    XCTAssertEqual(viewModel.pendingMessages.first?.status, .failed)

    noteRepository.shouldFailSaving = false
    viewModel.retryPendingMessage(id: try XCTUnwrap(viewModel.pendingMessages.first?.id))

    XCTAssertTrue(viewModel.pendingMessages.isEmpty)
    XCTAssertEqual(viewModel.messages.map(\.content), ["전송 실패 메시지"])
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

@MainActor
private final class RetriableNoteRepositorySpy: NoteRepository {
  var shouldFailSaving: Bool
  private(set) var savedNotes: [Note] = []

  init(shouldFailSaving: Bool) {
    self.shouldFailSaving = shouldFailSaving
  }

  func fetch(contactId: UUID?) throws -> [Note] {
    savedNotes.filter { $0.contactId == contactId }
  }

  func save(_ note: Note) throws {
    if shouldFailSaving {
      throw TestError.saveFailed
    }
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
  private var analyses: [Note.ID: NoteImageAnalysisResult]

  init(analyses: [Note.ID: NoteImageAnalysisResult] = [:]) {
    self.analyses = analyses
  }

  func fetch(noteId: Note.ID) -> NoteImageAnalysisResult? {
    analyses[noteId]
  }

  func fetchAll() -> [Note.ID: NoteImageAnalysisResult] {
    analyses
  }

  func save(
    noteId: Note.ID,
    result: NoteImageAnalysisResult,
    analyzedAt: Date
  ) {
    saveCount += 1
    analyses[noteId] = result
  }
}

private enum TestError: Error {
  case analysisFailed
  case saveFailed
}
