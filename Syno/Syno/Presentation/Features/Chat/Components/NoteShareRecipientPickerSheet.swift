import SwiftData
import SwiftUI

/// 노트를 다른 연락처에게 복제해 전달할 수 있는 수신자 선택 시트입니다.
struct NoteShareRecipientPickerSheet: View {
  private enum Filter: Hashable {
    case all
    case group(String)

    var title: String {
      switch self {
      case .all:
        "All"
      case let .group(name):
        name
      }
    }
  }

  @Environment(\.dismiss) private var dismiss
  @Query(sort: \StoredContact.name) private var storedContacts: [StoredContact]
  @Query(sort: \StoredGroup.sortIndex) private var storedGroups: [StoredGroup]

  let note: Note
  let currentContactID: Contact.ID
  let repository: any NoteRepository
  let onShared: () -> Void

  @State private var selectedFilter: Filter = .all
  @State private var selectedRecipientIDs: Set<Contact.ID> = []
  @State private var toast: Toast?

  var body: some View {
    VStack(spacing: 0) {
      AddContactSheetHeader(
        title: "공유하기",
        onCancel: { dismiss() },
        isApplyEnabled: !selectedRecipientIDs.isEmpty
      ) {
        shareNote()
      }

      filterChips

      ScrollView {
        LazyVStack(spacing: 8) {
          ForEach(filteredContacts, id: \.id) { contact in
            recipientRow(contact)
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 28)
      }
    }
    .padding(.top, 32)
    .background(Color.gray50)
    .toast(item: $toast)
  }

  private var filters: [Filter] {
    [.all] + storedGroups.map { .group($0.name) }
  }

  private var allRecipientContacts: [Contact] {
    storedContacts
      .map(\.contact)
      .filter { $0.id != currentContactID }
  }

  private var filteredContacts: [Contact] {
    allRecipientContacts
      .filter { contact in
        switch selectedFilter {
        case .all:
          true
        case let .group(name):
          contact.group.compare(name, options: .caseInsensitive) == .orderedSame
        }
      }
  }

  private var filterChips: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(filters, id: \.self) { filter in
          NoteFilterChip(
            title: filter.title,
            isSelected: selectedFilter == filter
          ) {
            selectedFilter = filter
          }
        }
      }
      .padding(.horizontal, 16)
    }
    .padding(.bottom, 8)
  }

  private func recipientRow(_ contact: Contact) -> some View {
    let isSelected = selectedRecipientIDs.contains(contact.id)

    return Button {
      if isSelected {
        selectedRecipientIDs.remove(contact.id)
      } else {
        selectedRecipientIDs.insert(contact.id)
      }
    } label: {
      HStack(spacing: 12) {
        Image(.logo)
          .profileImage(data: contact.profileImageData, size: 44)

        VStack(alignment: .leading, spacing: 2) {
          Text(contact.name)
            .typeStyle(.callout)
            .foregroundStyle(.gray950)
            .lineLimit(1)

          if !contact.group.isEmpty {
            Text(contact.group)
              .typeStyle(.footnote)
              .foregroundStyle(.gray400)
          }
        }

        Spacer()

        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(isSelected ? .violet500 : .gray300)
      }
      .padding(.horizontal, 16)
      .frame(minHeight: 64)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    .buttonStyle(.plain)
  }

  private func shareNote() {
    let recipients = allRecipientContacts.filter { selectedRecipientIDs.contains($0.id) }
    guard !recipients.isEmpty else {
      return
    }

    do {
      try repository.saveSharedCopies(of: note, for: recipients)
      onShared()
      dismiss()
    } catch {
      toast = Toast(
        message: "노트 공유 실패했습니다",
        style: .failure,
        action: Toast.Action(title: "다시 시도") {
          shareNote()
        }
      )
    }
  }
}

private extension NoteRepository {
  func saveSharedCopies(of note: Note, for recipients: [Contact]) throws {
    for recipient in recipients {
      try save(
        Note(
          contactId: recipient.id,
          contactName: recipient.name,
          content: note.content,
          imageData: note.imageData,
          profileImageData: recipient.profileImageData
        )
      )
    }
  }
}
