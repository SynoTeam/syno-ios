import Foundation
import OSLog
import SwiftData

@MainActor
final class SwiftDataContactRepository: ContactRepository {
  private let modelContext: ModelContext
  private let searchIndex: (any SearchIndexing)?
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "ContactRepository"
  )

  init(
    modelContext: ModelContext,
    searchIndex: (any SearchIndexing)? = nil
  ) {
    self.modelContext = modelContext
    self.searchIndex = searchIndex
  }

  func fetchAll() throws -> [Contact] {
    do {
      let descriptor = FetchDescriptor<StoredContact>(
        sortBy: [SortDescriptor(\.createdAt)]
      )
      return try modelContext.fetch(descriptor).map(\.contact)
    } catch {
      logger.error("Failed to fetch contacts: \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }

  func save(_ contact: Contact) throws {
    do {
      let id = contact.id
      let descriptor = FetchDescriptor<StoredContact>(
        predicate: #Predicate { $0.id == id }
      )

      if let storedContact = try modelContext.fetch(descriptor).first {
        storedContact.update(with: contact)
      } else {
        modelContext.insert(StoredContact(contact: contact))
      }

      try modelContext.save()
      if let searchIndex {
        let document = SearchDocument.contact(
          id: contact.id,
          text: [
            contact.role,
            contact.company,
            contact.email,
            contact.phone,
            contact.group,
            contact.note
          ].joined(separator: "\n")
        )
        Task { await searchIndex.index(document) }
      }
    } catch {
      modelContext.rollback()
      logger.error("Failed to save contact \(contact.id): \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }

  func delete(id: Contact.ID) throws {
    do {
      let descriptor = FetchDescriptor<StoredContact>(
        predicate: #Predicate { $0.id == id }
      )
      if let storedContact = try modelContext.fetch(descriptor).first {
        let noteDescriptor = FetchDescriptor<StoredNote>(
          predicate: #Predicate { $0.contactId == id }
        )
        let storedNotes = try modelContext.fetch(noteDescriptor)
        let noteIDs = Set(storedNotes.map(\.id))

        let noteAnalyses = try modelContext.fetch(
          FetchDescriptor<StoredNoteImageAnalysis>()
        )
        let noteEmbeddings = try modelContext.fetch(
          FetchDescriptor<StoredNoteEmbedding>()
        )
        let contactEmbeddings = try modelContext.fetch(
          FetchDescriptor<StoredContactEmbedding>()
        )

        for note in storedNotes {
          modelContext.delete(note)
        }
        for analysis in noteAnalyses where noteIDs.contains(analysis.noteId) {
          modelContext.delete(analysis)
        }
        for embedding in noteEmbeddings where noteIDs.contains(embedding.noteId) {
          modelContext.delete(embedding)
        }
        for embedding in contactEmbeddings where embedding.contactId == id {
          modelContext.delete(embedding)
        }
        modelContext.delete(storedContact)
        try modelContext.save()
        if let searchIndex {
          let key = SearchDocumentKey(kind: .contact, sourceId: id)
          Task { await searchIndex.remove(key) }
          for noteID in noteIDs {
            let key = SearchDocumentKey(kind: .note, sourceId: noteID)
            Task { await searchIndex.remove(key) }
          }
        }
      }
    } catch {
      modelContext.rollback()
      logger.error("Failed to delete contact \(id): \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }
}
