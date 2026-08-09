//
//  SearchEmptyStateView.swift
//  Syno
//

import SwiftUI

struct SearchEmptyStateView: View {
  let category: SearchCategory

  var body: some View {
    VStack(spacing: 18) {
      Image(imageName)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 96, height: 96)

      Text(message)
        .typeStyle(.headline)
        .foregroundStyle(.gray500)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 24)
  }

  private var imageName: ImageResource {
    switch category {
    case .all: .emptySearch
    case .text: .emptyText
    case .photo: .emptyPhoto
    case .link: .emptyLink
    case .voice: .emptyArchive
    }
  }

  private var message: String {
    switch category {
    case .all:
      "검색 결과가 없습니다."
    case .text, .photo, .link, .voice: "일치하는 노트가 없습니다."
    }
  }
}
