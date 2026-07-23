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
    switch selectedFilter {
    case .all:
      notes
    case .favorite:
      notes.filter(\.isFavorite)
    }
  }

  var isEmpty: Bool {
    notes.isEmpty
  }

  func replaceNotes(_ notes: [Note]) {
    self.notes = Self.latestNotesByContact(from: notes)

    if selectedFilter == .favorite && !self.notes.contains(where: \.isFavorite) {
      selectedFilter = .all
    }
  }
}

private extension NotesViewModel {
  static func latestNotesByContact(from notes: [Note]) -> [Note] {
    var latestNotes: [String: Note] = [:]

    for note in notes {
      let key = note.contactId?.uuidString ?? note.contactName

      if let currentNote = latestNotes[key], currentNote.createdAt >= note.createdAt {
        continue
      }

      latestNotes[key] = note
    }

    return latestNotes.values.sorted { $0.createdAt > $1.createdAt }
  }
}
