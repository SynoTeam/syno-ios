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
  @ObservationIgnored private let userDefaults: UserDefaults
  @ObservationIgnored private var searchTask: Task<Void, Never>?

  private static let recentSearchesKey = "search.recentQueries"
  private static let recentSearchLimit = 6

  init(
    modelContext: ModelContext,
    userDefaults: UserDefaults = .standard
  ) {
    self.modelContext = modelContext
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
        self?.performSearch(for: searchTerm)
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
    performSearch(for: normalizedQuery)
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

  private func performSearch(for searchTerm: String) {
    guard !searchTerm.isEmpty else {
      results = []
      isSearching = false
      return
    }

    do {
      let contactPredicate = #Predicate<StoredContact> { contact in
        contact.name.localizedStandardContains(searchTerm)
          || contact.role.localizedStandardContains(searchTerm)
          || contact.company.localizedStandardContains(searchTerm)
          || contact.email.localizedStandardContains(searchTerm)
          || contact.phone.localizedStandardContains(searchTerm)
          || contact.group.localizedStandardContains(searchTerm)
      }
      let notePredicate = #Predicate<StoredNote> { note in
        note.contactName.localizedStandardContains(searchTerm)
          || note.content.localizedStandardContains(searchTerm)
      }

      let storedContacts = try modelContext.fetch(
        FetchDescriptor<StoredContact>(
          predicate: contactPredicate,
          sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
      )
      let storedNotes = try modelContext.fetch(
        FetchDescriptor<StoredNote>(
          predicate: notePredicate,
          sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
      )

      var contactsById = Dictionary(
        uniqueKeysWithValues: storedContacts.map { ($0.id, $0.contact) }
      )
      let missingContactIds = Set(storedNotes.compactMap(\.contactId))
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

      let contactResults = storedContacts.map {
        SearchResult.contact($0.contact, createdAt: $0.createdAt)
      }
      let noteResults = storedNotes.map { storedNote in
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
