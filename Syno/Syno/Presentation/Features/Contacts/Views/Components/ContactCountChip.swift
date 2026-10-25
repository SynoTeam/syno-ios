//
//  ContactCountChip.swift
//  Syno
//

import SwiftUI

/// 섹션 제목 옆에 연락처 수를 보여주는 칩입니다. 자릿수가 달라도 같은 크기를 유지합니다.
struct ContactCountChip: View {
  let count: Int

  var body: some View {
    Text("\(count)")
      .typeStyle(.footnoteEmphasized)
      .foregroundStyle(.violet600)
      .padding(.horizontal, 6)
      .frame(minWidth: 22, minHeight: 22)
      .background(.violet100)
      .clipShape(Capsule())
  }
}

#Preview {
  HStack {
    ContactCountChip(count: 1)
    ContactCountChip(count: 24)
    ContactCountChip(count: 128)
  }
  .padding()
}
