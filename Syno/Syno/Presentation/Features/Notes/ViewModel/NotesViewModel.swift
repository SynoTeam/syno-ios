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
  private(set) var groupNames: [String] = []
  private var groupNamesByContactID: [UUID: String] = [:]

  init(notes: [Note] = []) {
    self.notes = notes
  }

  var availableFilters: [NoteFilter] {
    var filters: [NoteFilter] = [.all]

    if notes.contains(where: \.isFavorite) {
      filters.append(.favorite)
    }

    return filters + groupNames.map(NoteFilter.group)
  }

  var filteredNotes: [Note] {
    let filteredNotes: [Note]

    switch selectedFilter {
    case .all:
      filteredNotes = notes
    case .favorite:
      filteredNotes = notes.filter(\.isFavorite)
    case let .group(groupName):
      filteredNotes = notes.filter { note in
        guard let contactID = note.contactId else {
          return false
        }
        return groupNamesByContactID[contactID] == groupName
      }
    }

    let pinnedNotes = filteredNotes
      .filter(\.isPinned)
      .sorted { $0.createdAt > $1.createdAt }
    let unpinnedNotes = filteredNotes.filter { !$0.isPinned }

    switch sortOrder {
    case .newest:
      return pinnedNotes + unpinnedNotes.sorted { $0.createdAt > $1.createdAt }
    case .name:
      return pinnedNotes + unpinnedNotes.sorted {
        $0.contactName.localizedStandardCompare($1.contactName) == .orderedAscending
      }
    }
  }

  var isEmpty: Bool {
    notes.isEmpty
  }

  func replaceNotes(
    _ notes: [Note],
    favoriteContactIds: Set<UUID> = [],
    pinnedContactIds: Set<UUID> = [],
    groupNames: [String] = [],
    groupNamesByContactID: [UUID: String] = [:]
  ) {
    self.notes = Self.latestNotesByContact(
      from: notes,
      favoriteContactIds: favoriteContactIds,
      pinnedContactIds: pinnedContactIds
    )
    self.groupNames = groupNames
    self.groupNamesByContactID = groupNamesByContactID

    if !availableFilters.contains(selectedFilter) {
      selectedFilter = .all
    }
  }
}

private extension NotesViewModel {
  static func latestNotesByContact(
    from notes: [Note],
    favoriteContactIds: Set<UUID>,
    pinnedContactIds: Set<UUID>
  ) -> [Note] {
    var latestNotes: [String: Note] = [:]

    for var note in notes {
      note.isFavorite = note.contactId.map(favoriteContactIds.contains) ?? false
      note.isPinned = note.contactId.map(pinnedContactIds.contains) ?? false
      let key = note.contactId?.uuidString ?? note.contactName

      if let currentNote = latestNotes[key], currentNote.createdAt >= note.createdAt {
        continue
      }

      latestNotes[key] = note
    }

    return latestNotes.values.sorted { $0.createdAt > $1.createdAt }
  }
}
