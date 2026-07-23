//
//  NotesViewModel.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import Foundation
import Observation

/// 노트 목록 화면의 필터와 표시 데이터를 관리하는 ViewModel입니다.
@Observable
final class NotesViewModel {
  var selectedFilter: NoteFilter = .all
  var sortOrder: NoteSortOrder = .newest
  private(set) var notes: [Note]

  init(notes: [Note] = []) {
    self.notes = notes
  }

  var availableFilters: [NoteFilter] {
    if notes.contains(where: \.isFavorite) {
      return NoteFilter.allCases
    }

    return [.all]
  }

  var filteredNotes: [Note] {
    let filteredNotes: [Note]

    switch selectedFilter {
    case .all:
      filteredNotes = notes
    case .favorite:
      filteredNotes = notes.filter(\.isFavorite)
    }

    switch sortOrder {
    case .newest:
      return filteredNotes.sorted { $0.createdAt > $1.createdAt }
    case .name:
      return filteredNotes.sorted {
        $0.contactName.localizedStandardCompare($1.contactName) == .orderedAscending
      }
    }
  }

  var isEmpty: Bool {
    notes.isEmpty
  }

  func replaceNotes(
    _ notes: [Note],
    favoriteContactIds: Set<UUID> = []
  ) {
    self.notes = Self.latestNotesByContact(
      from: notes,
      favoriteContactIds: favoriteContactIds
    )

    if selectedFilter == .favorite && !self.notes.contains(where: \.isFavorite) {
      selectedFilter = .all
    }
  }
}

private extension NotesViewModel {
  static func latestNotesByContact(
    from notes: [Note],
    favoriteContactIds: Set<UUID>
  ) -> [Note] {
    var latestNotes: [String: Note] = [:]

    for var note in notes {
      note.isFavorite = note.contactId.map(favoriteContactIds.contains) ?? false
      let key = note.contactId?.uuidString ?? note.contactName

      if let currentNote = latestNotes[key], currentNote.createdAt >= note.createdAt {
        continue
      }

      latestNotes[key] = note
    }

    return latestNotes.values.sorted { $0.createdAt > $1.createdAt }
  }
}
