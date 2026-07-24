import OSLog
import SwiftData

@MainActor
final class SearchIndexBackfillService {
  private let modelContext: ModelContext
  private let searchIndex: any SearchIndexing
  private let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  private let labelTranslator: any LabelTranslating
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "SearchIndexBackfill"
  )
  private var hasStarted = false

  init(
    modelContext: ModelContext,
    searchIndex: any SearchIndexing,
    noteImageAnalysisRepository: any NoteImageAnalysisRepository,
    labelTranslator: any LabelTranslating
  ) {
    self.modelContext = modelContext
    self.searchIndex = searchIndex
    self.noteImageAnalysisRepository = noteImageAnalysisRepository
    self.labelTranslator = labelTranslator
  }

  func start() async {
    guard !hasStarted else { return }
    hasStarted = true

    do {
      let contacts = try modelContext.fetch(FetchDescriptor<StoredContact>())
      let notes = try modelContext.fetch(FetchDescriptor<StoredNote>())
      let imageAnalyses =
        (try? await noteImageAnalysisRepository.fetchAll()) ?? [:]
      let documents = contacts.map {
        SearchDocument.contact(
          id: $0.id,
          text: [
            $0.role, $0.company, $0.email,
            $0.phone, $0.group, $0.note
          ].joined(separator: "\n")
        )
      } + notes.map {
        SearchDocument.note(
          id: $0.id,
          text: semanticText(
            for: $0,
            analysis: imageAnalyses[$0.id]
          )
        )
      }
      await searchIndex.backfill(documents, batchSize: 20)
    } catch {
      logger.error(
        "Failed to prepare search index backfill: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  private func semanticText(
    for note: StoredNote,
    analysis: NoteImageAnalysisResult?
  ) -> String {
    guard note.imageData != nil, let analysis else {
      return note.content
    }
    return (
      [note.content]
        + labelTranslator.searchTerms(for: analysis.labels)
        + [analysis.ocrText]
    )
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }
}
