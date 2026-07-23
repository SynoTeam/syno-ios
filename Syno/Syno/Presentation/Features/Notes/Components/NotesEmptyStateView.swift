//
//  NotesEmptyStateView.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import SwiftUI

/// 저장된 노트가 없을 때 표시하는 empty state입니다.
struct NotesEmptyStateView: View {
  var body: some View {
    VStack(spacing: 28) {
      Image(.logo)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 148, height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 20))

      Text("아직 기록이 없습니다.\n새로운 노트를 남겨보세요.")
        .typeStyle(.headline)
        .foregroundStyle(.gray500)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 160)
  }
}
