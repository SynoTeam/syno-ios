//
//  AddContactFormSection.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 연락처 추가 폼의 섹션 제목과 내용을 세로로 배치하는 래퍼 뷰입니다.
struct AddContactFormSection<Content: View>: View {
  /// 섹션 상단에 표시할 제목입니다.
  let title: String

  /// 섹션 내부에 표시할 입력 컴포넌트입니다.
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .typeStyle(.subheadlineEmphasized)
        .foregroundStyle(.gray500)

      content()
    }
  }
}
