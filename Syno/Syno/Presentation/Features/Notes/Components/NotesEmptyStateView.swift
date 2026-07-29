//
//  NotesEmptyStateView.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import SwiftUI

/// 연락처 및 노트 수에 따라 표시하는 empty state입니다.
struct NotesEmptyStateView: View {
  enum State: Equatable {
    case noContacts
    case noNotes
  }

  let state: State
  let onAddContact: (() -> Void)?

  var body: some View {
    VStack(spacing: 28) {
      Image(.emptyList)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 120, height: 120)

      Text(message)
        .typeStyle(.headline)
        .foregroundStyle(.gray500)
        .multilineTextAlignment(.center)

      if state == .noContacts, let onAddContact {
        Button("연락처 추가하기", action: onAddContact)
          .typeStyle(.subheadlineEmphasized)
          .foregroundStyle(.gray700)
          .frame(minHeight: 40)
          .padding(.horizontal, 16)
          .background(.gray100)
          .clipShape(Capsule())
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 116)
  }

  private var message: String {
    switch state {
    case .noContacts:
      "환영합니다!\n연락처를 추가해보세요."
    case .noNotes:
      "아직 기록이 없습니다.\n새로운 노트를 남겨보세요."
    }
  }
}
