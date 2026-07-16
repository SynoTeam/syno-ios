//
//  ContactsView.swift
//  Syno
//
//  Created by 이승진 on 7/14/26.
//

import SwiftUI

struct ContactsView: View {
  @State private var viewModel = ContactsViewModel()
  @State private var isFavoriteCollapsed = false
  @State private var isAllCollapsed = false
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        header
        
        if let myContact = viewModel.myContact {
          ContactsRowView(
            name: myContact.name,
            role: myContact.role,
            company: myContact.company,
            style: .me
          )
        }
        
        ContactsSectionView(
          title: "Favorite",
          count: viewModel.favoriteContacts.count,
          contacts: viewModel.favoriteContacts,
          isCollapsed: $isFavoriteCollapsed,
          onToggleFavorite: viewModel.toggleFavorite,
          onDelete: viewModel.deleteContact
        )
        ContactsSectionView(
          title: "All",
          count: viewModel.regularContactCount,
          contacts: viewModel.regularContacts,
          isCollapsed: $isAllCollapsed,
          onToggleFavorite: viewModel.toggleFavorite,
          onDelete: viewModel.deleteContact
        )
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 20)
    }
    .background(Color(.systemGroupedBackground))
  }
  
  private var header: some View {
    HStack {
      Text("Contacts")
        .typeStyle(.screenTitle)
        .foregroundStyle(.gray950)
      
      Spacer()
      
      NavigationLink {
        AddContactView()
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
}

#Preview {
  NavigationStack {
    ContactsView()
  }
}
