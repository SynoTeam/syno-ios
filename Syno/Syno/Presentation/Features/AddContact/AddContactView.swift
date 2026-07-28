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
  @State private var viewModel: AddContactViewModel
  @State private var isShowingGroupSheet = false
  @State private var isShowingCountryCodeSheet = false
  @State private var isShowingDeviceContactPicker = false

  /// 저장된 연락처에서 수집한 그룹 목록입니다.
  let existingGroups: [String]

  /// 편집할 기존 연락처입니다. 값이 없으면 새 연락처를 추가합니다.
  let existingContact: Contact?

  let onSave: (Contact) -> Bool
  let onDelete: ((Contact.ID) -> Bool)?
  let onDeleted: (() -> Void)?

  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?

  init(
    existingContact: Contact? = nil,
    existingGroups: [String] = [],
    onSave: @escaping (Contact) -> Bool,
    onDelete: ((Contact.ID) -> Bool)? = nil,
    onDeleted: (() -> Void)? = nil
  ) {
    _viewModel = State(initialValue: AddContactViewModel(contact: existingContact))
    self.existingContact = existingContact
    self.existingGroups = existingGroups
    self.onSave = onSave
    self.onDelete = onDelete
    self.onDeleted = onDeleted
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        AddContactPhotoPickerView(selectedImageData: binding(\.selectedImageData))
        importDeviceContactButton
        contactForm
        deleteButton
      }
      .padding(.horizontal, 16)
      .padding(.top, 32)
      .padding(.bottom, 40)
    }
    .background(Color.gray50)
    .scrollDismissesKeyboard(.interactively)
    .dismissKeyboardOnTap($focusedField)
    .navigationTitle(existingContact == nil ? "연락처 추가" : "연락처 편집")
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
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
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

  @ViewBuilder
  private var deleteButton: some View {
    if existingContact != nil, onDelete != nil {
      Button(action: requestDeleteConfirmation) {
        Label("연락처 삭제하기", systemImage: "trash")
          .typeStyle(.headline)
          .foregroundStyle(.errorRed)
          .frame(maxWidth: .infinity, minHeight: 52)
          .background(.errorRed.opacity(0.08))
          .clipShape(Capsule())
      }
      .buttonStyle(.plain)
      .padding(.top, 8)
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
    guard onSave(viewModel.makeContact()) else {
      let message = existingContact == nil ? "연락처 저장에 실패했습니다" : "연락처 편집에 실패했습니다"
      toast = Toast(
        message: message,
        style: .failure,
        action: Toast.Action(title: "다시 시도") {
          saveContact()
        }
      )
      return
    }
    dismiss()
  }

  private func requestDeleteConfirmation() {
    confirmationAlert = DestructiveConfirmationAlert(
      title: "해당 연락처를\n영구적으로 삭제하겠습니까?",
      message: "연락처와 모든 노트와 파일이 삭제됩니다. 이 작업은 되돌릴 수 없습니다."
    ) {
      deleteContact()
    }
  }

  private func deleteContact() {
    guard let existingContact, let onDelete else {
      return
    }

    guard onDelete(existingContact.id) else {
      toast = Toast(
        message: "연락처 삭제 실패하였습니다",
        style: .failure,
        action: Toast.Action(title: "다시 시도") {
          deleteContact()
        }
      )
      return
    }

    onDeleted?()
    dismiss()
  }
}

#Preview {
  NavigationStack {
    AddContactView(existingGroups: ["스터디", "Portfolio"]) { _ in true }
  }
}
