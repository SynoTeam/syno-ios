//
//  ContactsDeleteView.swift
//  Syno
//

import SwiftUI

struct ContactsDeleteView: View {
  let viewModel: ContactsViewModel
  let onDeleted: (Int) -> Void

  @State private var selectedContactIDs: Set<Contact.ID>
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?

  init(
    viewModel: ContactsViewModel,
    initiallySelectedContactID: Contact.ID,
    onDeleted: @escaping (Int) -> Void
  ) {
    self.viewModel = viewModel
    self.onDeleted = onDeleted
    _selectedContactIDs = State(initialValue: [initiallySelectedContactID])
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        if !viewModel.favoriteContacts.isEmpty {
          ContactsDeleteSection(
            title: "Favorite",
            count: viewModel.favoriteContacts.count,
            contacts: viewModel.favoriteContacts,
            selectedContactIDs: $selectedContactIDs
          )
        }

        ContactsDeleteAllSection(
          contacts: viewModel.regularContacts,
          selectedContactIDs: $selectedContactIDs
        )
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 28)
    }
    .background(Color.gray50)
    .navigationTitle("연락처 삭제")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(action: requestDeleteConfirmation) {
          Image(systemName: "checkmark")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(selectedContactIDs.isEmpty ? .violet500.opacity(0.45) : .white)
            .frame(width: 44, height: 44)
            .background(selectedContactIDs.isEmpty ? .violet100 : .violet600)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(selectedContactIDs.isEmpty)
        .accessibilityLabel("선택한 연락처 삭제")
      }
      .sharedBackgroundVisibility(.hidden)
    }
    .onChange(of: viewModel.contacts) { _, contacts in
      selectedContactIDs.formIntersection(Set(contacts.map(\.id)))
    }
    .onChange(of: viewModel.persistenceError) { _, errorMessage in
      guard let errorMessage else {
        return
      }
      toast = Toast(
        message: errorMessage,
        style: .failure
      )
      viewModel.clearPersistenceError()
    }
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
  }

  private func requestDeleteConfirmation() {
    guard !selectedContactIDs.isEmpty else {
      return
    }
    confirmationAlert = DestructiveConfirmationAlert(
      title: deleteConfirmationTitle,
      message: "연락처와 모든 노트와 파일이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다."
    ) {
      confirmDelete()
    }
  }

  private var deleteConfirmationTitle: String {
    selectedContactIDs.count > 1
      ? "해당 연락처 \(selectedContactIDs.count)건을\n영구적으로 삭제하겠습니까?"
      : "해당 연락처를\n영구적으로 삭제하겠습니까?"
  }

  private func confirmDelete() {
    guard let deletedCount = viewModel.deleteContacts(ids: selectedContactIDs) else {
      return
    }

    onDeleted(deletedCount)
  }
}

#Preview {
  let contact = Contact(
    name: "Sample User",
    role: "",
    company: "",
    group: "Design"
  )

  NavigationStack {
    ContactsDeleteView(
      viewModel: ContactsViewModel(
        repository: PreviewRepositories.contact,
        contacts: [contact],
        myProfileId: UUID()
      ),
      initiallySelectedContactID: contact.id,
      onDeleted: { _ in }
    )
  }
}
