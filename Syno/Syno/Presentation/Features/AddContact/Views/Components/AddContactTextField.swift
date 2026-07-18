//
//  AddContactTextField.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 연락처 추가 화면에서 공통 스타일과 포커스 이동을 적용한 단일 줄 입력 필드입니다.
struct AddContactTextField: View {
  /// 입력값이 비어 있을 때 표시할 placeholder입니다.
  let placeholder: String

  /// 부모 폼 상태와 연결된 입력 문자열입니다.
  @Binding var text: String

  /// 이 입력 필드가 담당하는 포커스 대상입니다.
  let field: AddContactField

  /// 키보드 return 버튼에 표시할 submit 타입입니다.
  let submitLabel: SubmitLabel

  /// 부모 뷰에서 관리하는 현재 포커스 상태입니다.
  let focusedField: FocusState<AddContactField?>.Binding

  /// return 입력 시 실행할 포커스 이동 액션입니다.
  let onSubmit: () -> Void

  init(
    _ placeholder: String,
    text: Binding<String>,
    field: AddContactField,
    submitLabel: SubmitLabel = .next,
    focusedField: FocusState<AddContactField?>.Binding,
    onSubmit: @escaping () -> Void
  ) {
    self.placeholder = placeholder
    _text = text
    self.field = field
    self.submitLabel = submitLabel
    self.focusedField = focusedField
    self.onSubmit = onSubmit
  }

  var body: some View {
    TextField(placeholder, text: $text)
      .typeStyle(.body)
      .foregroundStyle(.gray950)
      .frame(height: 54)
      .lineLimit(1)
      .focused(focusedField, equals: field)
      .submitLabel(submitLabel)
      .onSubmit(onSubmit)
  }
}
