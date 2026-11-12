import Foundation
import Testing
@testable import Syno

/// 채팅을 열 때 미리보기가 없는 링크 노트의 미리보기를 가져오는 규칙입니다 (#126).
/// 공유 확장으로 저장한 링크나, 보낼 때 미리보기를 못 가져온 링크가 대상입니다.
@MainActor
struct ChatLinkPreviewBackfillTests {
  private let contact = Contact(name: "홍길동", role: "", company: "")
  private let preview = NoteLinkPreviewResult(
    title: "Example",
    imageURL: nil,
    siteURL: URL(string: "https://example.com")!
  )

  @Test("미리보기가 없는 링크 노트는 채팅을 열 때 미리보기를 가져와 저장하고 보여준다")
  func loadFetchesMissingPreview() async throws {
    let note = makeNote("https://example.com")
    let fetcher = LinkPreviewFetcherSpy(result: preview)
    let repository = LinkPreviewRepositorySpy()
    let viewModel = makeViewModel(notes: [note], fetcher: fetcher, repository: repository)

    await viewModel.loadMessages()
    await waitUntil { viewModel.linkPreviews[note.id] != nil }

    #expect(fetcher.requestedURLs == [URL(string: "https://example.com")!])
    #expect(repository.savedNoteIds == [note.id])
    #expect(viewModel.linkPreviews[note.id] == preview)
  }

  @Test("이미 미리보기가 저장된 노트는 다시 가져오지 않는다")
  func loadSkipsNotesWithSavedPreview() async throws {
    let note = makeNote("https://example.com")
    let fetcher = LinkPreviewFetcherSpy(result: preview)
    let repository = LinkPreviewRepositorySpy(previews: [note.id: preview])
    let viewModel = makeViewModel(notes: [note], fetcher: fetcher, repository: repository)

    await viewModel.loadMessages()
    await settle()

    #expect(fetcher.requestedURLs.isEmpty)
    #expect(viewModel.linkPreviews[note.id] == preview)
  }

  @Test("링크가 없는 노트는 미리보기를 요청하지 않는다", arguments: ["안녕하세요", "", "사진"])
  func loadSkipsNotesWithoutLink(content: String) async throws {
    let fetcher = LinkPreviewFetcherSpy(result: preview)
    let viewModel = makeViewModel(notes: [makeNote(content)], fetcher: fetcher)

    await viewModel.loadMessages()
    await settle()

    #expect(fetcher.requestedURLs.isEmpty)
  }

  @Test("같은 화면에서 채팅을 여러 번 다시 읽어도 같은 노트는 한 번만 요청한다")
  func repeatedLoadsRequestOnce() async throws {
    let note = makeNote("https://example.com")
    let fetcher = LinkPreviewFetcherSpy(result: nil)
    let viewModel = makeViewModel(notes: [note], fetcher: fetcher)

    await viewModel.loadMessages()
    await viewModel.loadMessages()
    await settle()

    #expect(fetcher.requestedURLs.count == 1)
  }

  @Test("미리보기를 못 가져오면 텍스트로 두고 오류를 띄우지 않으며, 다음에 채팅을 열 때 다시 시도한다")
  func failedFetchIsRetriedOnNextOpen() async throws {
    let note = makeNote("https://example.com")
    let notes = InMemoryNoteRepository(notes: [note])
    let failingFetcher = LinkPreviewFetcherSpy(result: nil)
    let firstOpen = makeViewModel(noteRepository: notes, fetcher: failingFetcher)

    await firstOpen.loadMessages()
    await waitUntil { failingFetcher.requestedURLs.count == 1 }
    await settle()

    #expect(firstOpen.linkPreviews[note.id] == nil)
    #expect(firstOpen.persistenceError == nil)

    let fetcher = LinkPreviewFetcherSpy(result: preview)
    let secondOpen = makeViewModel(noteRepository: notes, fetcher: fetcher)

    await secondOpen.loadMessages()
    await waitUntil { secondOpen.linkPreviews[note.id] != nil }

    #expect(fetcher.requestedURLs.count == 1)
    #expect(secondOpen.linkPreviews[note.id] == preview)
  }

  // MARK: - Helpers

  private func makeNote(_ content: String) -> Note {
    Note(contactId: contact.id, contactName: contact.name, content: content)
  }

  private func makeViewModel(
    notes: [Note] = [],
    noteRepository: InMemoryNoteRepository? = nil,
    fetcher: LinkPreviewFetcherSpy,
    repository: LinkPreviewRepositorySpy? = nil
  ) -> ChatViewModel {
    ChatViewModel(
      contact: contact,
      repository: noteRepository ?? InMemoryNoteRepository(notes: notes),
      imageAnalyzer: UnusedImageAnalyzer(),
      imageAnalysisRepository: EmptyImageAnalysisRepository(),
      linkPreviewFetcher: fetcher,
      linkPreviewRepository: repository ?? LinkPreviewRepositorySpy(),
      labelTranslator: StaticLabelDictionary(translations: [:]),
      voiceTranscriber: UnusedVoiceTranscriberStub(),
      voiceTranscriptRepository: EmptyVoiceTranscriptRepositoryStub()
    )
  }

  /// 화면 밖에서 시작된 미리보기 작업이 끝날 때까지 기다립니다.
  private func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<100 where !condition() {
      try? await Task.sleep(for: .milliseconds(10))
    }
  }

  /// 요청하지 않아야 하는 경우, 혹시 시작된 작업이 끝날 시간을 줍니다.
  private func settle() async {
    try? await Task.sleep(for: .milliseconds(100))
  }
}

// MARK: - Test doubles

/// 요청한 URL을 기록하고, 정해 둔 결과를 돌려줍니다. 결과가 nil이면 실패합니다.
@MainActor
private final class LinkPreviewFetcherSpy: NoteLinkPreviewFetching {
  private(set) var requestedURLs: [URL] = []
  private let result: NoteLinkPreviewResult?

  init(result: NoteLinkPreviewResult?) {
    self.result = result
  }

  func fetchPreview(for url: URL) async throws -> NoteLinkPreviewResult {
    requestedURLs.append(url)
    guard let result else { throw URLError(.notConnectedToInternet) }
    return result
  }
}

@MainActor
private final class LinkPreviewRepositorySpy: NoteLinkPreviewRepository {
  private var previews: [Note.ID: NoteLinkPreviewResult]
  private(set) var savedNoteIds: [Note.ID] = []

  init(previews: [Note.ID: NoteLinkPreviewResult] = [:]) {
    self.previews = previews
  }

  func fetch(noteId: Note.ID) async throws -> NoteLinkPreviewResult? {
    previews[noteId]
  }

  func fetchAll() async throws -> [Note.ID: NoteLinkPreviewResult] {
    previews
  }

  func save(noteId: Note.ID, result: NoteLinkPreviewResult, fetchedAt: Date) async throws {
    previews[noteId] = result
    savedNoteIds.append(noteId)
  }
}

@MainActor
private final class InMemoryNoteRepository: NoteRepository {
  private var notes: [Note]

  init(notes: [Note]) {
    self.notes = notes
  }

  func fetch(contactId: UUID?) throws -> [Note] {
    notes.filter { $0.contactId == contactId }
  }

  func fetchAll() throws -> [Note] {
    notes
  }

  func save(_ note: Note) throws {
    notes.append(note)
  }

  func delete(id: Note.ID) throws {
    notes.removeAll { $0.id == id }
  }

  func deleteAll(contactIds: [UUID]) throws {
    notes.removeAll { $0.contactId.map(contactIds.contains) ?? false }
  }
}

private struct EmptyImageAnalysisRepository: NoteImageAnalysisRepository {
  func fetch(noteId: Note.ID) async throws -> NoteImageAnalysisResult? { nil }
  func fetchAll() async throws -> [Note.ID: NoteImageAnalysisResult] { [:] }
  func save(noteId: Note.ID, result: NoteImageAnalysisResult, analyzedAt: Date) async throws {}
}

private struct UnusedImageAnalyzer: NoteImageAnalyzing {
  func analyze(imageData: Data) async throws -> NoteImageAnalysisResult {
    NoteImageAnalysisResult(labels: [], ocrText: "")
  }
}
