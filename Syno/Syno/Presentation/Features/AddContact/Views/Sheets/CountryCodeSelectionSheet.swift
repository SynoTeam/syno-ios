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

  /// 국가번호 목록을 필터링하는 검색어입니다.
  @State private var searchQuery = ""

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
    NavigationStack {
      ScrollView {
        VStack(spacing: 8) {
          if filteredOptions.isEmpty {
            ContentUnavailableView("검색결과가 없습니다.", systemImage: "magnifyingglass")
              .frame(maxWidth: .infinity)
              .frame(height: 180)
          } else {
            ForEach(filteredOptions) { option in
              countryRow(option)
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 88)
      }
      .background(Color.gray50)
      .safeAreaInset(edge: .bottom, spacing: 0) {
        searchField
      }
      .navigationTitle("국가번호 선택")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: dismiss.callAsFunction) {
            Image(systemName: "xmark")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.gray950)
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button {
            onApply(draftCountryCode)
            dismiss()
          } label: {
            Image(systemName: "checkmark")
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(.violet500)
          }
        }
      }
    }
  }

  private func countryRow(_ option: CountryCodeOption) -> some View {
    let isSelected = draftCountryCode == option.code

    return Button {
      draftCountryCode = option.code
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "checkmark")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.violet500)
          .opacity(isSelected ? 1 : 0)

        Text(option.displayTitle)
          .typeStyle(isSelected ? .calloutEmphasized : .callout)
          .foregroundStyle(.gray900)

        Spacer()
      }
      .padding(.horizontal, 18)
      .frame(height: 54)
      .frame(maxWidth: .infinity)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 999))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private var filteredOptions: [CountryCodeOption] {
    CountryCodeSearch.results(
      options: AddContactViewModel.countryCodeOptions,
      query: searchQuery,
      selectedCountryCode: draftCountryCode
    )
  }

  private var searchField: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.gray500)

      TextField("검색하기", text: $searchQuery)
        .typeStyle(.body)
        .foregroundStyle(.gray950)
        .autocorrectionDisabled()

      Button {
        searchQuery = ""
      } label: {
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.gray400)
      }
      .buttonStyle(.plain)
      .disabled(searchQuery.isEmpty || filteredOptions.isEmpty)
      .opacity(searchQuery.isEmpty || filteredOptions.isEmpty ? 0.4 : 1)
      .accessibilityLabel("검색어 지우기")
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .glassEffect(.regular, in: .capsule)
    .padding(.horizontal, 16)
    .padding(.bottom, 8)
  }
}

#Preview {
  CountryCodeSelectionSheet(selectedCountryCode: "+82") { _ in }
}
