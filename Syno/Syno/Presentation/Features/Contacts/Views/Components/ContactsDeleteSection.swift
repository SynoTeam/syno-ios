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

  @State private var isCollapsed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader

      if !isCollapsed {
        LazyVStack(spacing: 2) {
          ForEach(contacts) { contact in
            ContactsDeleteRow(
              contact: contact,
              isSelected: selectedContactIDs.contains(contact.id)
            ) {
              toggleSelection(for: contact.id)
            }
          }
        }
        .transition(.opacity)
      }
    }
    .padding(16)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 28))
  }

  private var sectionHeader: some View {
    Button {
      withAnimation(.snappy(duration: 0.2)) {
        isCollapsed.toggle()
      }
    } label: {
      HStack(spacing: 8) {
        Text(title)
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.gray500)

        ContactCountChip(count: count)

        Spacer()

        Image(.chevronUp)
          .resizable()
          .renderingMode(.template)
          .frame(width: 16, height: 16)
          .foregroundStyle(.gray500)
          .rotationEffect(.degrees(isCollapsed ? 180 : 0))
      }
      .frame(minHeight: 22)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
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

  @State private var isCollapsed = false

  /// 그룹 이름 순으로 묶고, 그룹이 없는 연락처(빈 제목)는 맨 아래에 둡니다.
  private var groupedContacts: [(title: String, contacts: [Contact])] {
    Dictionary(grouping: contacts) { contact in
      contact.group.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    .map { (title: $0.key, contacts: $0.value) }
    .sorted {
      if $0.title.isEmpty != $1.title.isEmpty {
        return !$0.title.isEmpty
      }
      let result = $0.title.localizedStandardCompare($1.title)
      // 로케일 비교에서 같게 나와도 원본 그룹명으로 가려서 표시 순서가 항상 같게 한다.
      return result == .orderedSame ? $0.title < $1.title : result == .orderedAscending
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Button {
        withAnimation(.snappy(duration: 0.2)) {
          isCollapsed.toggle()
        }
      } label: {
        HStack(spacing: 8) {
          Text("All")
            .typeStyle(.calloutEmphasized)
            .foregroundStyle(.gray500)

          ContactCountChip(count: contacts.count)

          Spacer()

          Image(.chevronUp)
            .resizable()
            .renderingMode(.template)
            .frame(width: 16, height: 16)
            .foregroundStyle(.gray500)
            .rotationEffect(.degrees(isCollapsed ? 180 : 0))
        }
        .frame(minHeight: 22)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      if !isCollapsed {
        groupList
          .transition(.opacity)
      }
    }
    .padding(16)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 28))
  }

  private var groupList: some View {
    VStack(alignment: .leading, spacing: 16) {
      ForEach(groupedContacts, id: \.title) { group in
        VStack(alignment: .leading, spacing: 8) {
          if !group.title.isEmpty {
            Text(group.title)
              .typeStyle(.footnoteEmphasized)
              .foregroundStyle(.gray400)
              .padding(.horizontal, 8)
          }

          LazyVStack(spacing: 2) {
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
    title: "Favorites",
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
