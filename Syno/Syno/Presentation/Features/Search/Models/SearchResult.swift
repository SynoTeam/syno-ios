//
//  SearchResult.swift
//  Syno
//

import Foundation

enum SearchResult: Identifiable {
  case contact(Contact, createdAt: Date)
  case note(Note, contact: Contact)

  var id: String {
    switch self {
    case .contact(let contact, _):
      "contact-\(contact.id.uuidString)"
    case .note(let note, _):
      "note-\(note.id.uuidString)"
    }
  }

  var category: SearchCategory {
    switch self {
    case .contact:
      .contacts
    case .note:
      .notes
    }
  }

  var sortDate: Date {
    switch self {
    case .contact(_, let createdAt):
      createdAt
    case .note(let note, _):
      note.createdAt
    }
  }
}
