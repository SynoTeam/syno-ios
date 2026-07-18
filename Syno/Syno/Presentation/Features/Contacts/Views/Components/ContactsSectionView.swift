//
//  ContactsSectionView.swift
//  Syno
//
//  Created by 이승진 on 7/16/26.
//

import SwiftUI

struct ContactsSectionView: View {
  let title: String
  let count: Int
  let contacts: [Contact]
  @Binding var isCollapsed: Bool
  let onToggleFavorite: (Contact.ID) -> Void
  let onDelete: (Contact.ID) -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      
      if !isCollapsed {
        LazyVStack(spacing: 16) {
          ForEach(contacts) { contact in
            NavigationLink {
              ContactDetailView(contact: contact)
            } label: {
              ContactsRowView(
                name: contact.name,
                role: contact.role,
                company: contact.company,
                profileImageData: contact.profileImageData
              )
            }
            .buttonStyle(.plain)
            .contextMenu {
              Button {
                onToggleFavorite(contact.id)
              } label: {
                Label(
                  contact.isFavorite ? "Remove Favorite" : "Add Favorite",
                  systemImage: contact.isFavorite ? "star.slash" : "star"
                )
              }

              Button(role: .destructive) {
                onDelete(contact.id)
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .padding(16)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 28))
    .animation(.snappy(duration: 0.2), value: isCollapsed)
  }
  
  private var header: some View {
    Button {
      isCollapsed.toggle()
    } label: {
      HStack(spacing: 8) {
        Text(title)
          .typeStyle(.headline)
          .foregroundStyle(.gray500)
        
        Text("\(count)")
          .typeStyle(.caption1)
          .foregroundStyle(.violet500)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.violet100)
          .clipShape(Capsule())
        
        Spacer()
        
        Image(systemName: "chevron.up")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.gray500)
          .rotationEffect(.degrees(isCollapsed ? 180 : 0))
      }
      .frame(minHeight: 22)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  ContactsSectionView(
    title: "All",
    count: 2,
    contacts: [
      Contact(name: "Sample User", role: "Product Designer", company: "@syno"),
      Contact(name: "Demo Contact", role: "iOS Developer", company: "@syno")
    ],
    isCollapsed: .constant(false),
    onToggleFavorite: { _ in },
    onDelete: { _ in }
  )
  .padding()
  .background(Color.gray50)
}
