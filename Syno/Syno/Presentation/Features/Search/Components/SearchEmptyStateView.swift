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
        .typeStyle(.headlineRegular)
        .foregroundStyle(.gray500)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 24)
    .emptyStatePosition()
  }

  private var imageName: ImageResource {
    switch category {
    case .all: .emptyDataSearch
    case .text: .emptyTextSearch
    case .photo: .emptyPhotoSearch
    case .link: .emptyDataSearch
    case .voice: .emptyVoiceSearch
    case .file: .emptyFileSearch
    }
  }

  private var message: String {
    switch category {
    case .all:
      "검색 결과가 없습니다."
    case .text, .photo, .link, .voice, .file: "일치하는 노트가 없습니다."
    }
  }
}
