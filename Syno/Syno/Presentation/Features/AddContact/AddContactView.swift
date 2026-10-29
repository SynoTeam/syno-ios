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
  @Environment(\.analytics) private var analytics
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
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          VStack(spacing: 20) {
            AddContactPhotoPickerView(selectedImageData: binding(\.selectedImageData))
            importDeviceContactButton
          }
          .frame(maxWidth: .infinity)
          contactForm

          // 하단에 고정하면 키보드가 올라올 때 버튼이 같이 올라와 입력창을 가리므로 스크롤 맨 아래에 둔다.
          deleteButton
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 24)
      }
      .toast(item: $toast)
    }
    .background(Color.gray50)
    .scrollDismissesKeyboard(.interactively)
    .dismissKeyboardOnTap($focusedField)
    .navigationBarTitleDisplayMode(.inline)
    .synoBackButton()
    .toolbar(.hidden, for: .tabBar)
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
  }

  private var importDeviceContactButton: some View {
    Button {
      focusedField = nil
      isShowingDeviceContactPicker = true
    } label: {
      Text("연락처 불러오기")
        .typeStyle(.subheadlineEmphasized)
        .foregroundStyle(.gray700)
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(.gray100)
        .clipShape(RoundedRectangle(cornerRadius: 999))
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
        Label {
          Text("연락처 삭제하기")
        } icon: {
          Image(.trash)
            .resizable()
            .renderingMode(.template)
            .frame(width: 20, height: 20)
        }
      }
      .buttonStyle(.cta(.destructive))
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
    if existingContact == nil {
      analytics.track(AnalyticsEvent.contactCreated)
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

    analytics.track(AnalyticsEvent.contactDeleted)
    onDeleted?()
    dismiss()
  }
}

#Preview {
  NavigationStack {
    AddContactView(existingGroups: ["스터디", "Portfolio"]) { _ in true }
  }
}
