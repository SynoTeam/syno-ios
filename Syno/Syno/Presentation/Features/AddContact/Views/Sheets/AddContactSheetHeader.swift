//
//  AddContactSheetHeader.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 연락처 추가 관련 바텀시트에서 공통으로 사용하는 X/제목/체크 헤더입니다.
struct AddContactSheetHeader: View {
  /// 헤더 중앙에 표시할 제목입니다.
  let title: String

  /// X 버튼을 눌렀을 때 실행할 취소 액션입니다.
  let onCancel: () -> Void

  /// 체크 버튼을 눌렀을 때 실행할 적용 액션입니다.
  let onApply: () -> Void

  var body: some View {
    HStack {
      Button(action: onCancel) {
        Image(systemName: "xmark")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.gray950)
          .frame(width: 44, height: 44)
      }
      .buttonStyle(.plain)

      Spacer()

      Text(title)
        .typeStyle(.headline)
        .foregroundStyle(.gray950)

      Spacer()

      Button(action: onApply) {
        Image(systemName: "checkmark")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.violet500)
          .frame(width: 44, height: 44)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 10)
    .padding(.bottom, 12)
  }
}
