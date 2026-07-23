//
//  ContactsView.swift
//  Syno
//
//  Created by 이승진 on 7/14/26.
//

import SwiftData
import SwiftUI

struct ContactsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \StoredContact.createdAt) private var storedContacts: [StoredContact]
  @State private var viewModel: ContactsViewModel
  @State private var isFavoriteCollapsed = false
  @State private var isAllCollapsed = true

  private let myProfileId: UUID

  init(userProfile: UserProfile? = nil) {
    let myProfileId = userProfile?.id ?? UUID()
    self.myProfileId = myProfileId
    _viewModel = State(initialValue: ContactsViewModel(myProfileId: myProfileId, myProfileName: userProfile?.displayName))
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        header
        
        if let myContact = viewModel.myContact {
          NavigationLink {
            MyPageView(contact: myContact) { contact in
              saveMyContact(contact)
            }
          } label: {
            ContactsRowView(
              name: myContact.name,
              role: "My Profile",
              company: myContact.company,
              profileImageData: myContact.profileImageData,
              style: .me
            )
          }
          .buttonStyle(.plain)
        }
        
        if !viewModel.favoriteContacts.isEmpty {
          ContactsSectionView(
            title: "Favorite",
            count: viewModel.favoriteContacts.count,
            contacts: viewModel.favoriteContacts,
            isCollapsed: $isFavoriteCollapsed,
            onToggleFavorite: toggleFavorite,
            onDelete: deleteContact
          )
        }

        ContactsSectionView(
          title: "All",
          count: viewModel.regularContactCount,
          contacts: viewModel.regularContacts,
          isCollapsed: $isAllCollapsed,
          onToggleFavorite: toggleFavorite,
          onDelete: deleteContact
        )

        if viewModel.regularContacts.isEmpty {
          emptyState
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 20)
    }
    .background(Color.gray50)
    .onAppear(perform: loadStoredContacts)
  }
  
  private var header: some View {
    HStack {
      Text("Contacts")
        .typeStyle(.header)
        .foregroundStyle(.gray950)
      
      Spacer()
      
      NavigationLink {
        AddContactView { contact in
          addContact(contact)
        }
      } label: {
        Image(systemName: "plus")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(.gray700)
          .frame(width: 44, height: 44)
          .background(.white)
          .clipShape(Circle())
      }
      .accessibilityLabel("Add Contact")
    }
  }

  private var emptyState: some View {
    VStack(spacing: 28) {
      Image(.logo)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 148, height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 20))

      Text("환영합니다!\n연락처를 추가해보세요.")
        .typeStyle(.headline)
        .foregroundStyle(.gray500)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 116)
  }

  private func loadStoredContacts() {
    let regularStoredContacts = storedContacts.filter { $0.id != myProfileId }
    viewModel.replaceRegularContacts(regularStoredContacts.map(\.contact))
    isAllCollapsed = viewModel.regularContacts.isEmpty

    if let storedMe = storedContacts.first(where: { $0.id == myProfileId }) {
      var meContact = storedMe.contact
      meContact.isMe = true
      viewModel.updateContact(meContact)
    }
  }

  private func saveMyContact(_ contact: Contact) {
    viewModel.updateContact(contact)

    if let storedContact = storedContacts.first(where: { $0.id == contact.id }) {
      storedContact.update(with: contact)
    } else {
      modelContext.insert(StoredContact(contact: contact))
    }

    saveContext()
  }

  private func addContact(_ contact: Contact) {
    viewModel.addContact(contact)
    isAllCollapsed = false
    modelContext.insert(StoredContact(contact: contact))
    saveContext()
  }

  private func deleteContact(id: Contact.ID) {
    viewModel.deleteContact(id: id)
    isAllCollapsed = viewModel.regularContacts.isEmpty

    if let storedContact = storedContacts.first(where: { $0.id == id }) {
      modelContext.delete(storedContact)
      saveContext()
    }
  }

  private func toggleFavorite(id: Contact.ID) {
    viewModel.toggleFavorite(id: id)

    guard
      let contact = viewModel.contacts.first(where: { $0.id == id }),
      let storedContact = storedContacts.first(where: { $0.id == id })
    else {
      return
    }

    storedContact.update(with: contact)
    saveContext()
  }

  private func saveContext() {
    try? modelContext.save()
  }
}

#Preview {
  NavigationStack {
    ContactsView()
  }
}
