//
//  ContactsDeleteSection.swift
//  Syno
//

import SwiftUI

struct ContactsDeleteSection: View {
  let title: String
  let count: Int
  let contacts: [Contact]
  @Binding var selectedContactIDs: Set<Contact.ID>

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader

      LazyVStack(spacing: 8) {
        ForEach(contacts) { contact in
          ContactsDeleteRow(
            contact: contact,
            isSelected: selectedContactIDs.contains(contact.id)
          ) {
            toggleSelection(for: contact.id)
          }
        }
      }
    }
    .padding(16)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 28))
  }

  private var sectionHeader: some View {
    HStack(spacing: 8) {
      Text(title)
        .typeStyle(.calloutEmphasized)
        .foregroundStyle(.gray500)

      Text("\(count)")
        .typeStyle(.footnoteEmphasized)
        .foregroundStyle(.violet500)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.violet100)
        .clipShape(Capsule())
    }
  }

  private func toggleSelection(for id: Contact.ID) {
    if selectedContactIDs.contains(id) {
      selectedContactIDs.remove(id)
    } else {
      selectedContactIDs.insert(id)
    }
  }
}

struct ContactsDeleteAllSection: View {
  let contacts: [Contact]
  @Binding var selectedContactIDs: Set<Contact.ID>

  private var groupedContacts: [(title: String, contacts: [Contact])] {
    Dictionary(grouping: contacts) { contact in
      let group = contact.group.trimmingCharacters(in: .whitespacesAndNewlines)
      return group.isEmpty ? "미분류" : group
    }
    .map { (title: $0.key, contacts: $0.value) }
    .sorted {
      $0.title.localizedStandardCompare($1.title) == .orderedAscending
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 8) {
        Text("All")
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.gray500)

        Text("\(contacts.count)")
          .typeStyle(.footnoteEmphasized)
          .foregroundStyle(.violet500)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.violet100)
          .clipShape(Capsule())
      }

      ForEach(groupedContacts, id: \.title) { group in
        VStack(alignment: .leading, spacing: 8) {
          Text(group.title)
            .typeStyle(.footnoteEmphasized)
            .foregroundStyle(.gray400)
            .padding(.horizontal, 8)

          LazyVStack(spacing: 8) {
            ForEach(group.contacts) { contact in
              ContactsDeleteRow(
                contact: contact,
                isSelected: selectedContactIDs.contains(contact.id)
              ) {
                toggleSelection(for: contact.id)
              }
            }
          }
        }
      }
    }
    .padding(16)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 28))
  }

  private func toggleSelection(for id: Contact.ID) {
    if selectedContactIDs.contains(id) {
      selectedContactIDs.remove(id)
    } else {
      selectedContactIDs.insert(id)
    }
  }
}

#Preview {
  ContactsDeleteSection(
    title: "Favorite",
    count: 2,
    contacts: [
      Contact(name: "Sample User", role: "", company: "", group: "Design"),
      Contact(name: "Demo Contact", role: "", company: "", group: "Design")
    ],
    selectedContactIDs: .constant([])
  )
  .padding()
  .background(Color.gray50)
}
