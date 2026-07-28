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
  @State private var isShowingDeviceContactPicker = false

  /// 저장된 연락처에서 수집한 그룹 목록입니다.
  let existingGroups: [String]

  let onSave: (Contact) -> Void

  init(
    existingGroups: [String] = [],
    onSave: @escaping (Contact) -> Void
  ) {
    self.existingGroups = existingGroups
    self.onSave = onSave
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        AddContactPhotoPickerView(selectedImageData: binding(\.selectedImageData))
        importDeviceContactButton
        contactForm
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
    .sheet(isPresented: $isShowingDeviceContactPicker) {
      DeviceContactPickerView { contact in
        viewModel.applyDeviceContact(contact)
      }
    }
  }

  private var importDeviceContactButton: some View {
    Button {
      focusedField = nil
      isShowingDeviceContactPicker = true
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "person.crop.circle.badge.plus")
          .font(.system(size: 18, weight: .semibold))

        Text("휴대폰 연락처에서 불러오기")
          .typeStyle(.subheadline)
      }
      .foregroundStyle(.gray700)
      .frame(maxWidth: .infinity, minHeight: 48)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private var contactForm: some View {
    ContactFormContentView(
      familyName: binding(\.familyName),
      givenName: binding(\.givenName),
      email: binding(\.email),
      countryCode: binding(\.countryCode),
      phone: binding(\.phone),
      url: binding(\.url),
      address: binding(\.address),
      birthday: binding(\.birthday),
      anniversary: binding(\.anniversary),
      socialLinks: binding(\.socialLinks),
      group: binding(\.group),
      note: binding(\.note),
      noteLimit: AddContactViewModel.noteLimit,
      focusedField: $focusedField
    ) {
      focusedField = nil
      isShowingCountryCodeSheet = true
    } onGroupTap: {
      isShowingGroupSheet = true
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
    AddContactView(existingGroups: ["스터디", "Portfolio"]) { _ in }
  }
}
