//
//  View+Keyboard.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

extension View {
  func dismissKeyboardOnTap(_ isFocused: FocusState<Bool>.Binding) -> some View {
    contentShape(Rectangle())
      .onTapGesture {
        isFocused.wrappedValue = false
      }
  }

  func dismissKeyboardOnTap<Field>(
    _ focusedField: FocusState<Field?>.Binding
  ) -> some View where Field: Hashable {
    contentShape(Rectangle())
      .onTapGesture {
        focusedField.wrappedValue = nil
      }
  }
}
