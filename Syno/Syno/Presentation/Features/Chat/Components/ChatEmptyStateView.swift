//
//  ChatEmptyStateView.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import SwiftUI

/// 채팅방에 아직 기록이 없을 때 표시하는 empty state입니다.
struct ChatEmptyStateView: View {
  var body: some View {
    VStack(spacing: 20) {
      Image(.logo)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 20))

      Text("아직 남긴 기록이 없습니다.\n아래 입력창에서 메모를 남겨보세요.")
        .typeStyle(.headline)
        .foregroundStyle(.gray500)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, minHeight: 420)
    .padding(.horizontal, 24)
  }
}
