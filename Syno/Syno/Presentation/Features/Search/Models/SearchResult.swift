//
//  SearchResult.swift
//  Syno
//

import Foundation

enum SearchResult: Identifiable {
  case text(Note, contact: Contact)
  case photo(Note, contact: Contact)
  case link(Note, contact: Contact, preview: NoteLinkPreviewResult)

  var id: String {
    switch self {
    case let .text(note, _), let .photo(note, _), let .link(note, _, _):
      "note-\(note.id.uuidString)"
    }
  }

  var category: SearchCategory {
    switch self {
    case .text: .text
    case .photo: .photo
    case .link: .link
    }
  }

  var sortDate: Date {
    switch self {
    case let .text(note, _), let .photo(note, _), let .link(note, _, _):
      note.createdAt
    }
  }
}
