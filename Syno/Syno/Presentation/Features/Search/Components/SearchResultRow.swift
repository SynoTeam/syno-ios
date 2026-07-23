//
//  SearchResultRow.swift
//  Syno
//

import SwiftUI

struct SearchResultRow: View {
  let result: SearchResult

  var body: some View {
    switch result {
    case .contact(let contact, _):
      ContactsRowView(
        name: contact.name,
        role: contact.role,
        company: contact.company,
        profileImageData: contact.profileImageData
      )
      .padding(12)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 20))

    case .note(let note, _):
      NoteRowView(note: note)
    }
  }
}
