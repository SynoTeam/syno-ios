//
//  SearchViewModel.swift
//  Syno
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SearchViewModel {
  var query = ""
  var selectedCategory: SearchCategory = .all
  private(set) var results: [SearchResult] = []
  private(set) var isSearching = false
  private(set) var recentSearches: [String] = []

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let searchIndex: any SearchIndexing
  @ObservationIgnored private let noteImageAnalysisRepository:
    any NoteImageAnalysisRepository
  @ObservationIgnored private let noteLinkPreviewRepository: any NoteLinkPreviewRepository
  @ObservationIgnored private let noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository
  @ObservationIgnored private let labelTranslator: any LabelTranslating
  @ObservationIgnored private let userDefaults: UserDefaults
  @ObservationIgnored private var searchTask: Task<Void, Never>?

  private static let recentSearchesKey = "search.recentQueries"
  private static let recentSearchLimit = 6

  init(
    modelContext: ModelContext,
    searchIndex: any SearchIndexing,
    noteImageAnalysisRepository: any NoteImageAnalysisRepository,
    noteLinkPreviewRepository: any NoteLinkPreviewRepository = NoopNoteLinkPreviewRepository(),
    noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository,
    labelTranslator: any LabelTranslating,
    userDefaults: UserDefaults = .standard
  ) {
    self.modelContext = modelContext
    self.searchIndex = searchIndex
    self.noteImageAnalysisRepository = noteImageAnalysisRepository
    self.noteLinkPreviewRepository = noteLinkPreviewRepository
    self.noteVoiceTranscriptRepository = noteVoiceTranscriptRepository
    self.labelTranslator = labelTranslator
    self.userDefaults = userDefaults
    recentSearches = userDefaults.stringArray(forKey: Self.recentSearchesKey) ?? []
  }

  var hasQuery: Bool {
    !normalizedQuery.isEmpty
  }

  var filteredResults: [SearchResult] {
    switch selectedCategory {
    case .all:
      results
    case .text, .photo, .link, .voice:
      results.filter { $0.category == selectedCategory }
    }
  }

  func results(for category: SearchCategory) -> [SearchResult] {
    results.filter { $0.category == category }
  }

  func updateQuery(_ query: String) {
    self.query = query
    searchTask?.cancel()

    guard hasQuery else {
      results = []
      isSearching = false
      return
    }

    isSearching = true
    let searchTerm = normalizedQuery

    searchTask = Task { [weak self] in
      do {
        try await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else {
          return
        }
        await self?.performSearch(for: searchTerm)
      } catch is CancellationError {
        return
      } catch {
        self?.results = []
        self?.isSearching = false
      }
    }
  }

  func clearQuery() {
    searchTask?.cancel()
    query = ""
    results = []
    isSearching = false
    selectedCategory = .all
  }

  func selectRecentSearch(_ search: String) {
    query = search
    commit(search)
    isSearching = true
    let searchTerm = normalizedQuery
    searchTask = Task { [weak self] in
      await self?.performSearch(for: searchTerm)
    }
  }

  func commitCurrentQuery() {
    guard hasQuery else {
      return
    }

    commit(normalizedQuery)
  }

  func removeRecentSearch(_ search: String) {
    recentSearches.removeAll { $0 == search }
    persistRecentSearches()
  }

  func clearRecentSearches() {
    recentSearches = []
    persistRecentSearches()
  }

  func cancelSearch() {
    searchTask?.cancel()
  }

  private var normalizedQuery: String {
    query.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func performSearch(for searchTerm: String) async {
    guard !searchTerm.isEmpty else {
      results = []
      isSearching = false
      return
    }

    do {
      let storedNotes = try modelContext.fetch(
        FetchDescriptor<StoredNote>(
          sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
      )
      let imageAnalyses =
        (try? await noteImageAnalysisRepository.fetchAll()) ?? [:]
      let linkPreviews = (try? await noteLinkPreviewRepository.fetchAll()) ?? [:]
      let voiceTranscripts = (try? await noteVoiceTranscriptRepository.fetchAll()) ?? [:]

      let keywordNotes = storedNotes.filter {
        searchableText(
          for: $0,
          analysis: imageAnalyses[$0.id],
          transcript: voiceTranscripts[$0.id]
        ).localizedStandardContains(searchTerm)
      }
      let keywordNoteIds = Set(keywordNotes.map(\.id))
      let semanticNoteDocuments = storedNotes.compactMap { storedNote in
        keywordNoteIds.contains(storedNote.id) ? nil :
          SearchDocument.note(
            id: storedNote.id,
            text: semanticText(
              for: storedNote,
              analysis: imageAnalyses[storedNote.id],
              transcript: voiceTranscripts[storedNote.id]
            )
          )
      }
      let scores = await searchIndex.scores(
        for: searchTerm,
        documents: semanticNoteDocuments
      )
      guard !Task.isCancelled, searchTerm == normalizedQuery else { return }
      let minimumDerivedScore = searchTerm.count > 1 ? 0.15 : 1

      let matchedNotes = storedNotes.filter { storedNote in
        keywordNoteIds.contains(storedNote.id)
          || scores[
            SearchDocumentKey(kind: .note, sourceId: storedNote.id),
            default: 0
          ] >= minimumDerivedScore
      }

      let referencedContactIds = Set(matchedNotes.compactMap(\.contactId))
      var contactsById: [UUID: Contact] = [:]

      if !referencedContactIds.isEmpty {
        let referencedContacts = try modelContext.fetch(
          FetchDescriptor<StoredContact>(
            predicate: #Predicate { referencedContactIds.contains($0.id) }
          )
        )

        for storedContact in referencedContacts {
          contactsById[storedContact.id] = storedContact.contact
        }
      }

      let noteResults = matchedNotes.map { storedNote in
        let note = storedNote.note
        let contact = note.contactId.flatMap { contactsById[$0] } ?? note.contact
        if note.imageData != nil { return SearchResult.photo(note, contact: contact) }
        if note.voiceMemoData != nil { return SearchResult.voice(note, contact: contact, transcript: voiceTranscripts[note.id]) }
        if let preview = linkPreviews[note.id] { return SearchResult.link(note, contact: contact, preview: preview) }
        return SearchResult.text(note, contact: contact)
      }

      results = noteResults.sorted {
        $0.sortDate > $1.sortDate
      }
      isSearching = false
    } catch {
      results = []
      isSearching = false
    }
  }

  private func searchableText(
    for note: StoredNote,
    analysis: NoteImageAnalysisResult?,
    transcript: NoteVoiceTranscriptResult?
  ) -> String {
    var components = [note.contactName, note.content]
    if note.imageData != nil, let analysis {
      components.append(
        contentsOf: labelTranslator.searchTerms(for: analysis.labels)
      )
      components.append(analysis.ocrText)
    }
    if note.voiceMemoData != nil, let transcript { components.append(transcript.text) }
    return components
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }

  private func semanticText(
    for note: StoredNote,
    analysis: NoteImageAnalysisResult?,
    transcript: NoteVoiceTranscriptResult?
  ) -> String {
    var components = [note.content]
    if note.imageData != nil, let analysis { components += labelTranslator.searchTerms(for: analysis.labels) + [analysis.ocrText] }
    if note.voiceMemoData != nil, let transcript { components.append(transcript.text) }
    return components.filter { !$0.isEmpty }.joined(separator: "\n")
  }

  private func commit(_ search: String) {
    recentSearches.removeAll { $0.localizedCaseInsensitiveCompare(search) == .orderedSame }
    recentSearches.insert(search, at: 0)
    recentSearches = Array(recentSearches.prefix(Self.recentSearchLimit))
    persistRecentSearches()
  }

  private func persistRecentSearches() {
    userDefaults.set(recentSearches, forKey: Self.recentSearchesKey)
  }
}
