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

  /// 저장된 연락처에서 수집한 그룹 목록입니다.
  let existingGroups: [String]

  let onSave: (Contact) -> Void

  init(
    contact: Contact,
    existingGroups: [String] = [],
    onSave: @escaping (Contact) -> Void
  ) {
    _viewModel = State(initialValue: MyPageEditViewModel(contact: contact))
    self.existingGroups = existingGroups
    self.onSave = onSave
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        AddContactPhotoPickerView(selectedImageData: binding(\.selectedImageData))
        contactForm
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
      GroupSelectionSheet(
        selectedGroup: viewModel.group,
        existingGroups: existingGroups
      ) { selectedGroup in
        viewModel.selectGroup(selectedGroup)
      }
      .presentationDetents([.large])
      .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $isShowingCountryCodeSheet) {
      CountryCodeSelectionSheet(selectedCountryCode: viewModel.countryCode) { countryCode in
        viewModel.selectCountryCode(countryCode)
      }
      .presentationDetents([.large])
      .presentationDragIndicator(.visible)
    }
  }

  private var contactForm: some View {
    ContactFormContentView(
      familyName: binding(\.familyName),
      givenName: binding(\.givenName),
      email: binding(\.email),
      countryCode: binding(\.countryCode),
      phone: binding(\.phone),
      linkedInURL: binding(\.linkedInURL),
      group: binding(\.group),
      note: binding(\.note),
      noteLimit: MyPageEditViewModel.noteLimit,
      focusedField: $focusedField
    ) {
      focusedField = nil
      isShowingCountryCodeSheet = true
    } onGroupTap: {
      isShowingGroupSheet = true
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
