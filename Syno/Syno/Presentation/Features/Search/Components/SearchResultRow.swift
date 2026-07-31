//
//  SearchResultRow.swift
//  Syno
//

import SwiftUI

struct SearchResultRow: View {
  let result: SearchResult

  var body: some View {
    switch result {
    case let .text(note, _):
      NoteRowView(note: note)
    case let .photo(note, _):
      if let data = note.imageData, let image = UIImage(data: data) {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(height: 84)
          .clipped()
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
    case let .link(_, _, preview):
      LinkPreviewCard(preview: preview)
    }
  }
}
