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
    await viewModel.linkPreviewBackfillTask?.value

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
    await viewModel.linkPreviewBackfillTask?.value

    #expect(fetcher.requestedURLs.isEmpty)
    #expect(viewModel.linkPreviews[note.id] == preview)
  }

  @Test("링크가 없는 노트는 미리보기를 요청하지 않는다", arguments: ["안녕하세요", "", "사진"])
  func loadSkipsNotesWithoutLink(content: String) async throws {
    let fetcher = LinkPreviewFetcherSpy(result: preview)
    let viewModel = makeViewModel(notes: [makeNote(content)], fetcher: fetcher)

    await viewModel.loadMessages()
    await viewModel.linkPreviewBackfillTask?.value

    #expect(fetcher.requestedURLs.isEmpty)
  }

  @Test("같은 화면에서 채팅을 여러 번 다시 읽어도 같은 노트는 한 번만 요청한다")
  func repeatedLoadsRequestOnce() async throws {
    let note = makeNote("https://example.com")
    let fetcher = LinkPreviewFetcherSpy(result: nil)
    let viewModel = makeViewModel(notes: [note], fetcher: fetcher)

    await viewModel.loadMessages()
    await viewModel.loadMessages()
    await viewModel.linkPreviewBackfillTask?.value

    #expect(fetcher.requestedURLs.count == 1)
  }

  @Test("미리보기를 못 가져오면 텍스트로 두고 오류를 띄우지 않으며, 다음에 채팅을 열 때 다시 시도한다")
  func failedFetchIsRetriedOnNextOpen() async throws {
    let note = makeNote("https://example.com")
    let notes = InMemoryNoteRepository(notes: [note])
    let failingFetcher = LinkPreviewFetcherSpy(result: nil)
    let firstOpen = makeViewModel(noteRepository: notes, fetcher: failingFetcher)

    await firstOpen.loadMessages()
    await firstOpen.linkPreviewBackfillTask?.value

    #expect(failingFetcher.requestedURLs.count == 1)
    #expect(firstOpen.linkPreviews[note.id] == nil)
    #expect(firstOpen.persistenceError == nil)

    let fetcher = LinkPreviewFetcherSpy(result: preview)
    let secondOpen = makeViewModel(noteRepository: notes, fetcher: fetcher)

    await secondOpen.loadMessages()
    await secondOpen.linkPreviewBackfillTask?.value

    #expect(fetcher.requestedURLs.count == 1)
    #expect(secondOpen.linkPreviews[note.id] == preview)
  }

  @Test("미리보기를 기다리는 동안 삭제된 노트는 요청하지 않는다")
  func deletedPendingNoteIsNotRequested() async throws {
    let first = makeNote("https://example.com/a")
    let second = makeNote("https://example.com/b")
    let fetcher = LinkPreviewFetcherSpy(result: preview)
    let repository = LinkPreviewRepositorySpy()
    let viewModel = makeViewModel(notes: [first, second], fetcher: fetcher, repository: repository)
    // 첫 링크를 가져오는 동안 사용자가 두 번째 링크를 지운다.
    fetcher.onFetch = { url in
      if url.absoluteString.hasSuffix("/a") { viewModel.deleteMessages(ids: [second.id]) }
    }

    await viewModel.loadMessages()
    await viewModel.linkPreviewBackfillTask?.value

    #expect(fetcher.requestedURLs.map(\.absoluteString) == ["https://example.com/a"])
    #expect(repository.savedNoteIds == [first.id])
    #expect(viewModel.linkPreviews[second.id] == nil)
  }

  @Test("미리보기를 가져오는 중에 삭제된 노트는 결과를 저장하지 않는다")
  func noteDeletedDuringFetchIsNotSaved() async throws {
    let note = makeNote("https://example.com")
    let fetcher = LinkPreviewFetcherSpy(result: preview)
    let repository = LinkPreviewRepositorySpy()
    let viewModel = makeViewModel(notes: [note], fetcher: fetcher, repository: repository)
    fetcher.onFetch = { _ in viewModel.deleteMessages(ids: [note.id]) }

    await viewModel.loadMessages()
    await viewModel.linkPreviewBackfillTask?.value

    #expect(repository.savedNoteIds.isEmpty)
    #expect(viewModel.linkPreviews[note.id] == nil)
  }

  @Test("저장된 미리보기를 읽지 못하면 이미 저장된 링크까지 다시 요청하지 않도록 이번에는 가져오지 않는다")
  func cacheLoadFailureSkipsBackfill() async throws {
    let note = makeNote("https://example.com")
    let fetcher = LinkPreviewFetcherSpy(result: preview)
    let repository = LinkPreviewRepositorySpy(failsFetchAll: true)
    let viewModel = makeViewModel(notes: [note], fetcher: fetcher, repository: repository)

    await viewModel.loadMessages()

    #expect(viewModel.linkPreviewBackfillTask == nil)
    #expect(fetcher.requestedURLs.isEmpty)
    #expect(viewModel.messages.map(\.id) == [note.id])
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
}

// MARK: - Test doubles

/// 요청한 URL을 기록하고, 정해 둔 결과를 돌려줍니다. 결과가 nil이면 실패합니다.
@MainActor
private final class LinkPreviewFetcherSpy: NoteLinkPreviewFetching {
  private(set) var requestedURLs: [URL] = []
  /// 요청을 받은 순간 실행할 동작입니다. 요청 중 사용자 동작을 흉내 낼 때 씁니다.
  var onFetch: ((URL) -> Void)?
  private let result: NoteLinkPreviewResult?

  init(result: NoteLinkPreviewResult?) {
    self.result = result
  }

  func fetchPreview(for url: URL) async throws -> NoteLinkPreviewResult {
    requestedURLs.append(url)
    onFetch?(url)
    guard let result else { throw URLError(.notConnectedToInternet) }
    return result
  }
}

@MainActor
private final class LinkPreviewRepositorySpy: NoteLinkPreviewRepository {
  private var previews: [Note.ID: NoteLinkPreviewResult]
  private let failsFetchAll: Bool
  private(set) var savedNoteIds: [Note.ID] = []

  init(previews: [Note.ID: NoteLinkPreviewResult] = [:], failsFetchAll: Bool = false) {
    self.previews = previews
    self.failsFetchAll = failsFetchAll
  }

  func fetch(noteId: Note.ID) async throws -> NoteLinkPreviewResult? {
    previews[noteId]
  }

  func fetchAll() async throws -> [Note.ID: NoteLinkPreviewResult] {
    if failsFetchAll { throw CocoaError(.fileReadUnknown) }
    return previews
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
