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
      Image(.emptyList)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 120, height: 120)

      Text("아직 남긴 기록이 없습니다.\n아래 입력창에서 메모를 남겨보세요.")
        .typeStyle(.headlineRegular)
        .foregroundStyle(.gray500)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 24)
    // 메시지 스크롤 영역 높이를 채워 세로 가운데에 둔다.
    .containerRelativeFrame(.vertical, alignment: .center)
    .emptyStatePosition()
  }
}
