import Foundation
import Observation
import OSLog
import PhotosUI
import SwiftUI
import UIKit

@MainActor
@Observable
final class ChatViewModel {
  private(set) var messages: [Note] = []
  var messageText = ""
  var messageSearchText = ""
  private(set) var persistenceError: String?
  private var imageAnalyses: [Note.ID: NoteImageAnalysisResult] = [:]

  let contact: Contact
  private let repository: any NoteRepository
  private let imageAnalyzer: any NoteImageAnalyzing
  private let imageAnalysisRepository: any NoteImageAnalysisRepository
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "ChatViewModel"
  )

  init(
    contact: Contact,
    repository: any NoteRepository,
    imageAnalyzer: any NoteImageAnalyzing,
    imageAnalysisRepository: any NoteImageAnalysisRepository
  ) {
    self.contact = contact
    self.repository = repository
    self.imageAnalyzer = imageAnalyzer
    self.imageAnalysisRepository = imageAnalysisRepository
  }

  var canSend: Bool {
    !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var messageSearchResults: [Note] {
    let searchText = messageSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !searchText.isEmpty else {
      return []
    }
    return messages.filter {
      searchableText(
        for: $0,
        analysis: imageAnalyses[$0.id]
      ).localizedStandardContains(searchText)
    }
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
    } catch {
      imageAnalyses = [:]
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
    save(note) {
      messageText = ""
    }
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

  func clearPersistenceError() {
    persistenceError = nil
  }

  private func makeNote(content: String, imageData: Data? = nil) -> Note {
    Note(
      contactId: contact.id,
      contactName: contact.name,
      content: content,
      imageData: imageData,
      profileImageData: contact.profileImageData
    )
  }

  private func searchableText(
    for note: Note,
    analysis: NoteImageAnalysisResult?
  ) -> String {
    var components = [note.content]
    if note.imageData != nil, let analysis {
      components.append(contentsOf: analysis.labels)
      components.append(analysis.ocrText)
    }
    return components
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }

  @discardableResult
  private func save(_ note: Note, onSuccess: () -> Void = {}) -> Bool {
    do {
      try repository.save(note)
      messages.append(note)
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
