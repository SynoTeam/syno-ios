//
//  MyPageEditView.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 내 프로필 정보를 수정하는 화면입니다.
///
/// 연락처 추가 화면과 같은 사진 선택, 국가번호 선택, 그룹 선택, 입력 필드 컴포넌트를 재사용합니다.
struct MyPageEditView: View {
  @Environment(\.dismiss) private var dismiss
  @FocusState private var focusedField: AddContactField?
  @State private var viewModel: MyPageEditViewModel
  @State private var isShowingGroupSheet = false
  @State private var isShowingCountryCodeSheet = false

  let onSave: (Contact) -> Void

  init(
    contact: Contact,
    onSave: @escaping (Contact) -> Void
  ) {
    _viewModel = State(initialValue: MyPageEditViewModel(contact: contact))
    self.onSave = onSave
  }

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
    .navigationTitle("프로필 편집")
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
          noteLimit: MyPageEditViewModel.noteLimit,
          focusedField: $focusedField
        )
      }
    }
  }

  private func binding<Value>(
    _ keyPath: ReferenceWritableKeyPath<MyPageEditViewModel, Value>
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
    MyPageEditView(
      contact: Contact(
        name: "정지우",
        role: "Apple",
        company: "",
        email: "dknwflosn@gmail.com",
        phone: "+82 010-1234-5678",
        linkedInURL: "https://www.linkedin.com/in/syno",
        note: "프로필 편집 예시"
      )
    ) { _ in }
  }
}
