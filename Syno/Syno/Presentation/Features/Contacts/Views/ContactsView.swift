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
  @State private var viewModel = ContactsViewModel()
  @State private var isFavoriteCollapsed = false
  @State private var isAllCollapsed = false

  init(userProfile: UserProfile? = nil) {
    _viewModel = State(initialValue: ContactsViewModel(myProfileName: userProfile?.displayName))
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        header
        
        if let myContact = viewModel.myContact {
          NavigationLink {
            MyPageView(contact: myContact) { contact in
              viewModel.updateContact(contact)
            }
          } label: {
            ContactsRowView(
              name: myContact.name,
              role: myContact.role,
              company: myContact.company,
              profileImageData: myContact.profileImageData,
              style: .me
            )
          }
          .buttonStyle(.plain)
        }
        
        ContactsSectionView(
          title: "Favorite",
          count: viewModel.favoriteContacts.count,
          contacts: viewModel.favoriteContacts,
          isCollapsed: $isFavoriteCollapsed,
          onToggleFavorite: toggleFavorite,
          onDelete: deleteContact
        )
        ContactsSectionView(
          title: "All",
          count: viewModel.regularContactCount,
          contacts: viewModel.regularContacts,
          isCollapsed: $isAllCollapsed,
          onToggleFavorite: toggleFavorite,
          onDelete: deleteContact
        )
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

  private func loadStoredContacts() {
    viewModel.replaceRegularContacts(storedContacts.map(\.contact))
  }

  private func addContact(_ contact: Contact) {
    viewModel.addContact(contact)
    modelContext.insert(StoredContact(contact: contact))
    saveContext()
  }

  private func deleteContact(id: Contact.ID) {
    viewModel.deleteContact(id: id)

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
