import Foundation
import Observation
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

  let contact: Contact
  private let repository: any NoteRepository

  init(contact: Contact, repository: any NoteRepository) {
    self.contact = contact
    self.repository = repository
  }

  var canSend: Bool {
    !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var messageSearchResults: [Note] {
    let searchText = messageSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !searchText.isEmpty else {
      return []
    }
    return messages.filter { $0.content.localizedStandardContains(searchText) }
  }

  func loadMessages() {
    do {
      messages = try repository.fetch(contactId: contact.id)
      persistenceError = nil
    } catch {
      handle(error)
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
      guard
        let rawImageData,
        let imageData = Self.compressedImageData(from: rawImageData)
      else {
        return
      }

      save(makeNote(content: "사진", imageData: imageData))
    } catch {
      handle(error)
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

  private func save(_ note: Note, onSuccess: () -> Void = {}) {
    do {
      try repository.save(note)
      messages.append(note)
      onSuccess()
      persistenceError = nil
    } catch {
      handle(error)
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
