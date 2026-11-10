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
  let groupRepository: any GroupRepository

  /// 편집할 기존 연락처입니다. 값이 없으면 새 연락처를 추가합니다.
  let existingContact: Contact?

  let onSave: (Contact) -> Bool

  @State private var toast: Toast?

  init(
    existingContact: Contact? = nil,
    groupRepository: any GroupRepository,
    onSave: @escaping (Contact) -> Bool
  ) {
    _viewModel = State(initialValue: AddContactViewModel(contact: existingContact))
    self.existingContact = existingContact
    self.groupRepository = groupRepository
    self.onSave = onSave
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
        groupRepository: groupRepository
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
}

#Preview {
  NavigationStack {
    AddContactView(groupRepository: PreviewRepositories.appContainer.groupService) { _ in true }
  }
}
