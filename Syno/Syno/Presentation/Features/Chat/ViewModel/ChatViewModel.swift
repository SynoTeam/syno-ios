import Foundation
import Observation
import OSLog
import PhotosUI
import SwiftUI
import UIKit

@MainActor
@Observable
final class ChatViewModel {
  enum VoiceMemoState: Equatable {
    case sendFailed
    case transcribing
    case transcriptFailed
    case transcribed(NoteVoiceTranscriptResult)
  }
  struct PendingMessage: Identifiable {
    enum Status: Equatable {
      case sending
      case failed
    }

    let id: UUID
    let note: Note
    var status: Status
  }

  struct MessageDaySection: Identifiable {
    let date: Date
    let messages: [Note]

    var id: Date { date }

    var title: String {
      let isCurrentYear = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
      let formatter = isCurrentYear ? Self.monthDayFormatter : Self.yearMonthDayFormatter
      return formatter.string(from: date)
    }

    private static let monthDayFormatter = makeFormatter("M월 d일 (E)")
    private static let yearMonthDayFormatter = makeFormatter("yyyy년 M월 d일 (E)")

    private static func makeFormatter(_ dateFormat: String) -> DateFormatter {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "ko_KR")
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.dateFormat = dateFormat
      return formatter
    }
  }

  private(set) var messages: [Note] = []
  private(set) var pendingMessages: [PendingMessage] = []
  var messageText = ""
  var messageSearchText = ""
  private(set) var persistenceError: String?
  private var imageAnalyses: [Note.ID: NoteImageAnalysisResult] = [:]
  private(set) var linkPreviews: [Note.ID: NoteLinkPreviewResult] = [:]
  private(set) var voiceMemoStates: [Note.ID: VoiceMemoState] = [:]

  let contact: Contact
  private let repository: any NoteRepository
  private let imageAnalyzer: any NoteImageAnalyzing
  private let imageAnalysisRepository: any NoteImageAnalysisRepository
  private let linkPreviewFetcher: any NoteLinkPreviewFetching
  private let linkPreviewRepository: any NoteLinkPreviewRepository
  private let labelTranslator: any LabelTranslating
  private let voiceTranscriber: any NoteVoiceTranscribing
  private let voiceTranscriptRepository: any NoteVoiceTranscriptRepository
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "ChatViewModel"
  )

  init(
    contact: Contact,
    repository: any NoteRepository,
    imageAnalyzer: any NoteImageAnalyzing,
    imageAnalysisRepository: any NoteImageAnalysisRepository,
    linkPreviewFetcher: any NoteLinkPreviewFetching = NoopNoteLinkPreviewFetcher(),
    linkPreviewRepository: any NoteLinkPreviewRepository = NoopNoteLinkPreviewRepository(),
    labelTranslator: any LabelTranslating,
    voiceTranscriber: any NoteVoiceTranscribing,
    voiceTranscriptRepository: any NoteVoiceTranscriptRepository
  ) {
    self.contact = contact
    self.repository = repository
    self.imageAnalyzer = imageAnalyzer
    self.imageAnalysisRepository = imageAnalysisRepository
    self.linkPreviewFetcher = linkPreviewFetcher
    self.linkPreviewRepository = linkPreviewRepository
    self.labelTranslator = labelTranslator
    self.voiceTranscriber = voiceTranscriber
    self.voiceTranscriptRepository = voiceTranscriptRepository
  }

  var canSend: Bool {
    !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var messageSearchResults: [Note] {
    let searchText = messageSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !searchText.isEmpty else {
      return []
    }
    return messages.filter { matches($0, searchText: searchText) }
  }

  /// 노트 본문과 사진 OCR/라벨을 대상으로 검색어 일치 여부를 반환합니다.
  func matches(_ note: Note, searchText: String) -> Bool {
    searchableText(for: note, analysis: imageAnalyses[note.id])
      .localizedStandardContains(searchText)
  }

  /// 같은 날짜에 작성된 메시지를 하나의 섹션으로 묶어 시간순으로 반환합니다.
  var messageSections: [MessageDaySection] {
    let calendar = Calendar.current
    let groupedMessages = Dictionary(grouping: messages) { message in
      calendar.startOfDay(for: message.createdAt)
    }

    return groupedMessages
      .map { date, messages in
        MessageDaySection(
          date: date,
          messages: messages.sorted { $0.createdAt < $1.createdAt }
        )
      }
      .sorted { $0.date < $1.date }
  }

  func loadMessages() async {
    do {
      messages = try repository.fetch(contactId: contact.id)
      persistenceError = nil
    } catch {
      handle(error)
      return
    }

    do {
      let messageIds = Set(messages.map(\.id))
      imageAnalyses = try await imageAnalysisRepository.fetchAll()
        .filter { messageIds.contains($0.key) }
      linkPreviews = try await linkPreviewRepository.fetchAll()
        .filter { messageIds.contains($0.key) }
      let transcripts = try await voiceTranscriptRepository.fetchAll()
      voiceMemoStates = Dictionary(uniqueKeysWithValues: messages.compactMap { note in
        guard note.voiceMemoData != nil, let transcript = transcripts[note.id] else { return nil }
        return (note.id, .transcribed(transcript))
      })
    } catch {
      imageAnalyses = [:]
      linkPreviews = [:]
      voiceMemoStates = [:]
      logger.debug(
        "Image analysis cache unavailable: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  func sendMessage() {
    let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else {
      return
    }

    let note = makeNote(content: trimmedText)
    enqueueMessage(note)
    messageText = ""
  }

  func retryPendingMessage(id: PendingMessage.ID) {
    guard let index = pendingMessages.firstIndex(where: { $0.id == id }) else {
      return
    }

    pendingMessages[index].status = .sending
    persistPendingMessage(id: id)
  }

  @discardableResult
  func deleteMessage(id: Note.ID) -> Bool {
    deleteMessages(ids: [id])
  }

  @discardableResult
  func deleteMessages(ids: Set<Note.ID>) -> Bool {
    var deletedIds: Set<Note.ID> = []
    var didFail = false

    for id in ids {
      do {
        try repository.delete(id: id)
        deletedIds.insert(id)
      } catch {
        didFail = true
      }
    }

    messages.removeAll { deletedIds.contains($0.id) }
    for id in deletedIds {
      imageAnalyses[id] = nil
      linkPreviews[id] = nil
      voiceMemoStates[id] = nil
    }

    guard !didFail else {
      return false
    }
    persistenceError = nil
    return true
  }

  func sendImage(from item: PhotosPickerItem?) async {
    guard let item else {
      return
    }

    do {
      let rawImageData = try await item.loadTransferable(type: Data.self)
      guard let rawImageData else {
        return
      }
      await sendImageData(rawImageData)
    } catch {
      handle(error)
    }
  }

  func sendImageData(_ rawImageData: Data) async {
    guard let imageData = Self.compressedImageData(from: rawImageData) else {
      return
    }
    let note = makeNote(content: "사진", imageData: imageData)
    guard save(note) else {
      return
    }

    do {
      let result = try await imageAnalyzer.analyze(imageData: imageData)
      try await imageAnalysisRepository.save(
        noteId: note.id,
        result: result,
        analyzedAt: Date()
      )
      imageAnalyses[note.id] = result
    } catch {
      logger.debug(
        "Image analysis skipped for note \(note.id): \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  func sendVoiceMemo(audioData: Data, duration: TimeInterval, waveform: [Float]) async {
    let note = makeNote(content: "무제-\(nextVoiceMemoNumber())", voiceMemoData: audioData, voiceMemoDuration: duration, voiceMemoWaveform: waveform)
    guard save(note) else { messages.append(note); voiceMemoStates[note.id] = .sendFailed; return }
    await transcribe(note)
  }

  func retryTranscription(for note: Note) async {
    await transcribe(note)
  }

  func retrySend(for note: Note) async {
    guard note.voiceMemoData != nil else { return }
    do {
      try repository.save(note)
      voiceMemoStates[note.id] = .transcribing
      await transcribe(note)
    } catch { voiceMemoStates[note.id] = .sendFailed }
  }

  private func transcribe(_ note: Note) async {
    guard let audioData = note.voiceMemoData else { return }
    voiceMemoStates[note.id] = .transcribing
    do {
      let result = try await voiceTranscriber.transcribe(audioData: audioData)
      try await voiceTranscriptRepository.save(noteId: note.id, result: result, transcribedAt: Date())
      voiceMemoStates[note.id] = .transcribed(result)
      if let firstLine = result.text.split(separator: "\n").first {
        update(note: note, content: String(firstLine))
      }
    } catch {
      let nsError = error as NSError
      logger.error(
        "Voice transcription failed for note \(note.id): \(nsError.domain, privacy: .public) code=\(nsError.code) \(nsError.localizedDescription, privacy: .public)"
      )
      voiceMemoStates[note.id] = .transcriptFailed
    }
  }

  func clearPersistenceError() {
    persistenceError = nil
  }

  private func makeNote(content: String, imageData: Data? = nil, voiceMemoData: Data? = nil, voiceMemoDuration: TimeInterval? = nil, voiceMemoWaveform: [Float]? = nil) -> Note {
    Note(
      contactId: contact.id,
      contactName: contact.name,
      content: content,
      imageData: imageData,
      voiceMemoData: voiceMemoData,
      voiceMemoDuration: voiceMemoDuration,
      voiceMemoWaveform: voiceMemoWaveform,
      profileImageData: contact.profileImageData
    )
  }

  private func update(note: Note, content: String) {
    var updated = note
    updated.content = content
    do {
      try repository.save(updated)
      if let index = messages.firstIndex(where: { $0.id == note.id }) { messages[index] = updated }
    } catch { handle(error) }
  }

  private func nextVoiceMemoNumber() -> Int {
    messages.filter { $0.voiceMemoData != nil }.count + 1
  }

  private func searchableText(
    for note: Note,
    analysis: NoteImageAnalysisResult?
  ) -> String {
    var components = [note.content]
    if note.imageData != nil, let analysis {
      components.append(
        contentsOf: labelTranslator.searchTerms(for: analysis.labels)
      )
      components.append(analysis.ocrText)
    }
    return components
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }

  private func enqueueMessage(_ note: Note) {
    let pendingMessage = PendingMessage(id: UUID(), note: note, status: .sending)
    pendingMessages.append(pendingMessage)

    Task { @MainActor in
      persistPendingMessage(id: pendingMessage.id)
    }
  }

  private func fetchLinkPreviewIfNeeded(for note: Note) {
    guard let url = firstURL(in: note.content) else { return }

    Task { @MainActor in
      do {
        let result = try await linkPreviewFetcher.fetchPreview(for: url)
        try await linkPreviewRepository.save(noteId: note.id, result: result, fetchedAt: Date())
        linkPreviews[note.id] = result
      } catch {
        logger.debug("Link preview unavailable: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  private func firstURL(in text: String) -> URL? {
    let range = NSRange(text.startIndex..., in: text)
    return (try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue))?
      .firstMatch(in: text, range: range)?
      .url
  }

  private func persistPendingMessage(id: PendingMessage.ID) {
    guard let index = pendingMessages.firstIndex(where: { $0.id == id }) else {
      return
    }

    let note = pendingMessages[index].note
    do {
      try repository.save(note)
      messages.append(note)
      fetchLinkPreviewIfNeeded(for: note)
      pendingMessages.removeAll { $0.id == id }
      persistenceError = nil
    } catch {
      pendingMessages[index].status = .failed
    }
  }

  @discardableResult
  private func save(_ note: Note, onSuccess: () -> Void = {}) -> Bool {
    do {
      try repository.save(note)
      messages.append(note)
      fetchLinkPreviewIfNeeded(for: note)
      onSuccess()
      persistenceError = nil
      return true
    } catch {
      handle(error)
      return false
    }
  }

  private static func compressedImageData(
    from data: Data,
    maxDimension: CGFloat = 1600
  ) -> Data? {
    guard let image = UIImage(data: data) else {
      return nil
    }

    let scale = min(1, maxDimension / max(image.size.width, image.size.height))
    let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let resizedImage = UIGraphicsImageRenderer(size: targetSize).image { _ in
      image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
    return resizedImage.jpegData(compressionQuality: 0.8)
  }

  private func handle(_ error: Error) {
    persistenceError = "메모를 저장하거나 불러오지 못했습니다. 다시 시도해주세요."
  }
}
