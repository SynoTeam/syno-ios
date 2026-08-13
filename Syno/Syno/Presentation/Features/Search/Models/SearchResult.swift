//
//  SearchResult.swift
//  Syno
//

import Foundation

enum SearchResult: Identifiable {
  case text(Note, contact: Contact)
  case photo(Note, contact: Contact)
  case link(Note, contact: Contact, preview: NoteLinkPreviewResult)
  case voice(Note, contact: Contact, transcript: NoteVoiceTranscriptResult?)
  case file(Note, contact: Contact)

  var id: String {
    switch self {
    case let .text(note, _), let .photo(note, _), let .link(note, _, _), let .voice(note, _, _), let .file(note, _):
      "note-\(note.id.uuidString)"
    }
  }

  var category: SearchCategory {
    switch self {
    case .text: .text
    case .photo: .photo
    case .link: .link
    case .voice: .voice
    case .file: .file
    }
  }

  var sortDate: Date {
    switch self {
    case let .text(note, _), let .photo(note, _), let .link(note, _, _), let .voice(note, _, _), let .file(note, _):
      note.createdAt
    }
  }
}
