import Foundation
import SwiftData

@ModelActor
actor SwiftDataNoteLinkPreviewRepository: NoteLinkPreviewRepository {
  func fetch(noteId: Note.ID) throws -> NoteLinkPreviewResult? {
    let descriptor = FetchDescriptor<StoredNoteLinkPreview>(
      predicate: #Predicate { $0.noteId == noteId }
    )
    guard
      let stored = try modelContext.fetch(descriptor).first,
      let siteURL = URL(string: stored.siteURLString)
    else {
      return nil
    }
    return NoteLinkPreviewResult(
      title: stored.title,
      imageURL: stored.imageURLString.flatMap(URL.init(string:)),
      siteURL: siteURL
    )
  }

  func fetchAll() throws -> [Note.ID: NoteLinkPreviewResult] {
    var results: [Note.ID: NoteLinkPreviewResult] = [:]
    for stored in try modelContext.fetch(FetchDescriptor<StoredNoteLinkPreview>()) {
      guard let siteURL = URL(string: stored.siteURLString) else { continue }
      results[stored.noteId] = NoteLinkPreviewResult(
        title: stored.title,
        imageURL: stored.imageURLString.flatMap(URL.init(string:)),
        siteURL: siteURL
      )
    }
    return results
  }

  func save(noteId: Note.ID, result: NoteLinkPreviewResult, fetchedAt: Date) throws {
    do {
      let descriptor = FetchDescriptor<StoredNoteLinkPreview>(
        predicate: #Predicate { $0.noteId == noteId }
      )
      if let stored = try modelContext.fetch(descriptor).first {
        stored.title = result.title
        stored.imageURLString = result.imageURL?.absoluteString
        stored.siteURLString = result.siteURL.absoluteString
        stored.fetchedAt = fetchedAt
      } else {
        modelContext.insert(StoredNoteLinkPreview(noteId: noteId, result: result, fetchedAt: fetchedAt))
      }
      try modelContext.save()
    } catch {
      modelContext.rollback()
      throw error
    }
  }
}
