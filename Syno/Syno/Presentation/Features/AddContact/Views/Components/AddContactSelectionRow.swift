//
//  AddContactSelectionRow.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 선택 시트를 여는 단일 행 버튼 컴포넌트입니다.
struct AddContactSelectionRow: View {
  /// 행에 표시할 현재 선택값 또는 placeholder입니다.
  let title: String

  /// 행을 눌렀을 때 실행할 액션입니다.
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Text(title)
          .typeStyle(.body)
          .foregroundStyle(.gray950)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(.gray500)
      }
      .frame(minHeight: 54)
      .padding(.horizontal, 22)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
