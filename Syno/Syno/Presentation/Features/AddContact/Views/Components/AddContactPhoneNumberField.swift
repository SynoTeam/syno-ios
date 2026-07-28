//
//  AddContactPhoneNumberField.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 국가번호 선택 버튼과 전화번호 입력 필드를 한 줄로 배치하는 컴포넌트입니다.
struct AddContactPhoneNumberField: View {
  /// 현재 선택된 국가번호입니다.
  let countryCode: String

  /// 부모 폼 상태와 연결된 전화번호 문자열입니다.
  @Binding var phone: String

  /// 부모 뷰에서 관리하는 현재 포커스 상태입니다.
  let focusedField: FocusState<AddContactField?>.Binding

  /// 국가번호 선택 버튼을 눌렀을 때 실행할 액션입니다.
  let onCountryCodeTap: () -> Void

  /// 전화번호 입력 후 return 시 실행할 포커스 이동 액션입니다.
  let onSubmit: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onCountryCodeTap) {
        HStack(spacing: 6) {
          Text(countryCode)
            .typeStyle(.subheadline)
            .foregroundStyle(.gray950)

          Image(systemName: "chevron.down")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.gray500)
        }
        .frame(width: 73, height: 38)
        .background(.gray100)
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
      .buttonStyle(.plain)

      TextField("전화번호", text: formattedPhone)
        .typeStyle(.body)
        .foregroundStyle(.gray950)
        .frame(height: 54)
        .lineLimit(1)
        .keyboardType(.phonePad)
        .focused(focusedField, equals: .phone)
        .submitLabel(.next)
        .onSubmit(onSubmit)
    }
  }

  private var formattedPhone: Binding<String> {
    Binding(
      get: { ContactPhoneNumberFormatter.hyphenated(phone) },
      set: { phone = ContactPhoneNumberFormatter.digitsOnly($0) }
    )
  }
}
