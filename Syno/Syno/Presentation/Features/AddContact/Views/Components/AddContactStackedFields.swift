//
//  AddContactStackedFields.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 여러 입력 필드를 하나의 흰색 카드 안에 쌓아 보여주는 래퍼 뷰입니다.
struct AddContactStackedFields<Content: View>: View {
  /// 카드 내부에 배치할 입력 필드들입니다.
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(spacing: 0) {
      content()
    }
    .padding(.horizontal, 22)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 22))
  }
}
