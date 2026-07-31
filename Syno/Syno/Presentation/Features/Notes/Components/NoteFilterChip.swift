//
//  NoteFilterChip.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import SwiftUI

/// 노트 목록 필터를 선택하는 pill 형태의 칩입니다.
struct NoteFilterChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .typeStyle(.subheadline)
        .foregroundStyle(isSelected ? .gray25 : .gray400)
        .padding(.horizontal, 16)
        .frame(height: 32)
        .background(isSelected ? .gray800 : .clear)
        .overlay {
          Capsule()
            .stroke(isSelected ? .clear : .gray200, lineWidth: 1)
        }
        .clipShape(Capsule())
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
  }
}
