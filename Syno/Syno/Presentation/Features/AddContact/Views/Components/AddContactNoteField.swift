//
//  AddContactNoteField.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 연락처의 한 줄 기록을 입력하고 글자 수를 표시하는 멀티라인 입력 컴포넌트입니다.
struct AddContactNoteField: View {
  /// 부모 폼 상태와 연결된 기록 문자열입니다.
  @Binding var note: String

  /// 기록 입력에 허용되는 최대 글자 수입니다.
  let noteLimit: Int

  /// 부모 뷰에서 관리하는 현재 포커스 상태입니다.
  let focusedField: FocusState<AddContactField?>.Binding

  /// 현재 입력 글자 수와 제한 글자 수를 함께 표시하는 문자열입니다.
  private var noteCountText: String {
    "\(note.count)/\(noteLimit)"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ZStack(alignment: .topLeading) {
        if note.isEmpty {
          Text("한 줄 기록을 입력하세요")
            .typeStyle(.body)
            .foregroundStyle(.gray400)
            .padding(EdgeInsets(top: 28, leading: 25, bottom: 0, trailing: 20))
            .allowsHitTesting(false)
        }

        TextEditor(text: $note)
          .typeStyle(.body)
          .foregroundStyle(.gray950)
          .scrollContentBackground(.hidden)
          .frame(minHeight: 210)
          .padding(20)
          .focused(focusedField, equals: .note)
      }
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 22))

      Text(noteCountText)
        .typeStyle(.footnote)
        .foregroundStyle(note.count == noteLimit ? .violet500 : .gray400)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
  }
}
