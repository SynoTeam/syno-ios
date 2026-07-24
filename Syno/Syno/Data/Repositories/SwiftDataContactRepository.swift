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
            contact.name,
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
        modelContext.delete(storedContact)
        try modelContext.save()
        if let searchIndex {
          let key = SearchDocumentKey(kind: .contact, sourceId: id)
          Task { await searchIndex.remove(key) }
        }
      }
    } catch {
      modelContext.rollback()
      logger.error("Failed to delete contact \(id): \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }
}
