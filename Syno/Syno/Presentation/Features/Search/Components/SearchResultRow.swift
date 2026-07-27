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
        group: contact.group,
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
