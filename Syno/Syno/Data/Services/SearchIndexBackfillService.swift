import OSLog
import SwiftData

@MainActor
final class SearchIndexBackfillService {
  private let modelContext: ModelContext
  private let searchIndex: any SearchIndexing
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "SearchIndexBackfill"
  )
  private var hasStarted = false

  init(modelContext: ModelContext, searchIndex: any SearchIndexing) {
    self.modelContext = modelContext
    self.searchIndex = searchIndex
  }

  func start() async {
    guard !hasStarted else { return }
    hasStarted = true

    do {
      let contacts = try modelContext.fetch(FetchDescriptor<StoredContact>())
      let notes = try modelContext.fetch(FetchDescriptor<StoredNote>())
      let documents = contacts.map {
        SearchDocument.contact(
          id: $0.id,
          text: [
            $0.name, $0.role, $0.company, $0.email,
            $0.phone, $0.group, $0.note
          ].joined(separator: "\n")
        )
      } + notes.map {
        SearchDocument.note(
          id: $0.id,
          text: [$0.contactName, $0.content].joined(separator: "\n")
        )
      }
      await searchIndex.backfill(documents, batchSize: 20)
    } catch {
      logger.error(
        "Failed to prepare search index backfill: \(error.localizedDescription, privacy: .public)"
      )
    }
  }
}
