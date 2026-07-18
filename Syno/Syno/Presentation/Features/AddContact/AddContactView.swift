//
//  AddContactView.swift
//  Syno
//
//  Created by 이승진 on 7/14/26.
//

import SwiftUI

/// 연락처 추가 화면입니다.
///
/// 입력 폼 상태는 `AddContactViewModel`이 소유하고, 화면은 사진 선택, 입력 필드,
/// 선택 시트 컴포넌트를 조립하는 역할만 담당합니다.
struct AddContactView: View {
  @Environment(\.dismiss) private var dismiss
  @FocusState private var focusedField: AddContactField?
  @State private var viewModel = AddContactViewModel()
  @State private var isShowingGroupSheet = false
  @State private var isShowingCountryCodeSheet = false

  let onSave: (Contact) -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        AddContactPhotoPickerView(selectedImageData: binding(\.selectedImageData))
        formContent
      }
      .padding(.horizontal, 16)
      .padding(.top, 32)
      .padding(.bottom, 40)
    }
    .background(Color.gray50)
    .scrollDismissesKeyboard(.interactively)
    .dismissKeyboardOnTap($focusedField)
    .navigationTitle("연락처 추가")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("완료", action: saveContact)
          .disabled(!viewModel.canSave)
      }
    }
    .sheet(isPresented: $isShowingGroupSheet) {
      GroupSelectionSheet(selectedGroup: viewModel.group) { selectedGroup in
        viewModel.selectGroup(selectedGroup)
      }
      .presentationDetents([.height(320)])
      .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $isShowingCountryCodeSheet) {
      CountryCodeSelectionSheet(selectedCountryCode: viewModel.countryCode) { countryCode in
        viewModel.selectCountryCode(countryCode)
      }
      .presentationDetents([.height(380)])
      .presentationDragIndicator(.visible)
    }
  }

  private var formContent: some View {
    VStack(alignment: .leading, spacing: 28) {
      AddContactFormSection(title: "이름") {
        AddContactStackedFields {
          AddContactTextField(
            "성",
            text: binding(\.familyName),
            field: .familyName,
            focusedField: $focusedField
          ) {
            focusedField = .givenName
          }
          Divider()
            .background(.gray50)
          AddContactTextField(
            "이름",
            text: binding(\.givenName),
            field: .givenName,
            focusedField: $focusedField
          ) {
            focusedField = .email
          }
        }
      }

      AddContactFormSection(title: "연락처") {
        AddContactStackedFields {
          AddContactTextField(
            "이메일",
            text: binding(\.email),
            field: .email,
            focusedField: $focusedField
          ) {
            focusedField = .phone
          }
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
          Divider()
            .background(.gray50)
          AddContactPhoneNumberField(
            countryCode: viewModel.countryCode,
            phone: binding(\.phone),
            focusedField: $focusedField
          ) {
            focusedField = nil
            isShowingCountryCodeSheet = true
          } onSubmit: {
            focusedField = .linkedInURL
          }
          Divider()
            .background(.gray50)
          AddContactTextField(
            "링크드인 URL",
            text: binding(\.linkedInURL),
            field: .linkedInURL,
            submitLabel: .done,
            focusedField: $focusedField
          ) {
            focusedField = nil
          }
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
        }
      }

      AddContactFormSection(title: "그룹 정보") {
        AddContactSelectionRow(
          title: viewModel.group.isEmpty ? "그룹 선택하기" : viewModel.group
        ) {
          focusedField = nil
          isShowingGroupSheet = true
        }
      }

      AddContactFormSection(title: "한 줄 기록") {
        AddContactNoteField(
          note: binding(\.note),
          noteLimit: AddContactViewModel.noteLimit,
          focusedField: $focusedField
        )
      }
    }
  }

  private func binding<Value>(
    _ keyPath: ReferenceWritableKeyPath<AddContactViewModel, Value>
  ) -> Binding<Value> {
    Binding(
      get: { viewModel[keyPath: keyPath] },
      set: { viewModel[keyPath: keyPath] = $0 }
    )
  }

  private func saveContact() {
    onSave(viewModel.makeContact())
    dismiss()
  }
}

#Preview {
  NavigationStack {
    AddContactView { _ in }
  }
}
