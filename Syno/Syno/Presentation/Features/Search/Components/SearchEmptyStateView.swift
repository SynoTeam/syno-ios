//
//  SearchEmptyStateView.swift
//  Syno
//

import SwiftUI

struct SearchEmptyStateView: View {
  let category: SearchCategory

  var body: some View {
    VStack(spacing: 18) {
      Image(systemName: iconName)
        .font(.system(size: 38, weight: .regular))
        .foregroundStyle(.gray300)

      Text(message)
        .typeStyle(.headline)
        .foregroundStyle(.gray500)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 24)
  }

  private var iconName: String {
    switch category {
    case .all:
      "magnifyingglass"
    case .text: "text.alignleft"
    case .photo: "photo"
    case .link: "link"
    }
  }

  private var message: String {
    switch category {
    case .all:
      "검색 결과가 없습니다."
    case .text, .photo, .link: "일치하는 노트가 없습니다."
    }
  }
}
