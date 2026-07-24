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
  @ObservationIgnored private let userDefaults: UserDefaults
  @ObservationIgnored private var searchTask: Task<Void, Never>?

  private static let recentSearchesKey = "search.recentQueries"
  private static let recentSearchLimit = 6

  init(
    modelContext: ModelContext,
    searchIndex: any SearchIndexing,
    userDefaults: UserDefaults = .standard
  ) {
    self.modelContext = modelContext
    self.searchIndex = searchIndex
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
    case .contacts, .notes:
      results.filter { $0.category == selectedCategory }
    }
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
      let storedContacts = try modelContext.fetch(
        FetchDescriptor<StoredContact>(
          sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
      )
      let storedNotes = try modelContext.fetch(
        FetchDescriptor<StoredNote>(
          sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
      )

      let keywordContacts = storedContacts.filter {
        searchableText(for: $0).localizedStandardContains(searchTerm)
      }
      let keywordNotes = storedNotes.filter {
        searchableText(for: $0).localizedStandardContains(searchTerm)
      }
      let keywordContactIds = Set(keywordContacts.map(\.id))
      let keywordNoteIds = Set(keywordNotes.map(\.id))
      let semanticContactDocuments = storedContacts.compactMap { storedContact in
        keywordContactIds.contains(storedContact.id) ? nil :
          SearchDocument.contact(id: storedContact.id, text: searchableText(for: storedContact))
      }
      let semanticNoteDocuments = storedNotes.compactMap { storedNote in
        keywordNoteIds.contains(storedNote.id) ? nil :
          SearchDocument.note(id: storedNote.id, text: searchableText(for: storedNote))
      }
      let scores = await searchIndex.scores(
        for: searchTerm,
        documents: semanticContactDocuments + semanticNoteDocuments
      )
      guard !Task.isCancelled, searchTerm == normalizedQuery else { return }
      let minimumDerivedScore = searchTerm.count > 1 ? 0.15 : 1

      let matchedContacts = storedContacts.filter { storedContact in
        keywordContactIds.contains(storedContact.id)
          || scores[
            SearchDocumentKey(kind: .contact, sourceId: storedContact.id),
            default: 0
          ] >= minimumDerivedScore
      }
      let matchedNotes = storedNotes.filter { storedNote in
        keywordNoteIds.contains(storedNote.id)
          || scores[
            SearchDocumentKey(kind: .note, sourceId: storedNote.id),
            default: 0
          ] >= minimumDerivedScore
      }

      var contactsById = Dictionary(
        uniqueKeysWithValues: matchedContacts.map { ($0.id, $0.contact) }
      )
      let missingContactIds = Set(matchedNotes.compactMap(\.contactId))
        .subtracting(contactsById.keys)

      if !missingContactIds.isEmpty {
        let additionalContacts = try modelContext.fetch(
          FetchDescriptor<StoredContact>(
            predicate: #Predicate { missingContactIds.contains($0.id) }
          )
        )

        for storedContact in additionalContacts {
          contactsById[storedContact.id] = storedContact.contact
        }
      }

      let contactResults = matchedContacts.map {
        SearchResult.contact($0.contact, createdAt: $0.createdAt)
      }
      let noteResults = matchedNotes.map { storedNote in
        let note = storedNote.note
        let contact = note.contactId.flatMap { contactsById[$0] } ?? note.contact
        return SearchResult.note(note, contact: contact)
      }

      results = (contactResults + noteResults).sorted {
        $0.sortDate > $1.sortDate
      }
      isSearching = false
    } catch {
      results = []
      isSearching = false
    }
  }

  private func searchableText(for contact: StoredContact) -> String {
    [
      contact.name,
      contact.role,
      contact.company,
      contact.email,
      contact.phone,
      contact.group,
      contact.note
    ].joined(separator: "\n")
  }

  private func searchableText(for note: StoredNote) -> String {
    [note.contactName, note.content].joined(separator: "\n")
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
