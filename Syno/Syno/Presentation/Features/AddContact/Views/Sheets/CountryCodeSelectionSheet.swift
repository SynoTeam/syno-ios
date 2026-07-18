//
//  CountryCodeSelectionSheet.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 국가번호를 임시 선택한 뒤 체크 버튼으로 적용하는 바텀시트입니다.
struct CountryCodeSelectionSheet: View {
  @Environment(\.dismiss) private var dismiss

  /// 시트 안에서만 변경되는 임시 국가번호 값입니다.
  @State private var draftCountryCode: String

  /// 체크 버튼을 눌렀을 때 부모 폼에 선택값을 반영하는 콜백입니다.
  let onApply: (String) -> Void

  init(
    selectedCountryCode: String,
    onApply: @escaping (String) -> Void
  ) {
    self.onApply = onApply
    _draftCountryCode = State(initialValue: selectedCountryCode)
  }

  var body: some View {
    VStack(spacing: 0) {
      AddContactSheetHeader(
        title: "국가번호 선택",
        onCancel: { dismiss() }
      ) {
        onApply(draftCountryCode)
        dismiss()
      }

      VStack(spacing: 0) {
        ForEach(AddContactViewModel.countryCodeOptions.indices, id: \.self) { index in
          let option = AddContactViewModel.countryCodeOptions[index]

          Button {
            draftCountryCode = option.code
          } label: {
            HStack(spacing: 12) {
              Text(option.countryName)
                .typeStyle(.body)
                .foregroundStyle(.gray950)

              Spacer()

              Text(option.code)
                .typeStyle(.body)
                .foregroundStyle(.gray500)

              if draftCountryCode == option.code {
                Image(systemName: "checkmark")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(.violet500)
              }
            }
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)

          if index < AddContactViewModel.countryCodeOptions.count - 1 {
            Divider()
              .background(.gray50)
              .padding(.horizontal, 20)
          }
        }
      }
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .padding(.horizontal, 16)

      Spacer(minLength: 0)
    }
    .padding(.top, 16)
    .background(Color.gray50)
  }
}

#Preview {
  CountryCodeSelectionSheet(selectedCountryCode: "+82") { _ in }
}
