//
//  ContactDetailView.swift
//  Syno
//
//  Created by 이승진 on 7/17/26.
//

import SwiftUI

struct ContactDetailView: View {
  @State private var toast: Toast?

  let contact: Contact
  let noteRepository: any NoteRepository
  let noteImageAnalyzer: any NoteImageAnalyzing
  let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  let linkPreviewFetcher: any NoteLinkPreviewFetching
  let noteLinkPreviewRepository: any NoteLinkPreviewRepository
  let labelTranslator: any LabelTranslating
  let viewModel: ContactsViewModel?
  let existingGroups: [String]
  let onDeleted: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(spacing: 20) {
          profileHeader
          contactInfoCard
          additionalInfoCard

          if !contact.note.isEmpty {
            noteCard
          }
        }
        .padding(.horizontal, 22)
        .padding(.top, 28)
        .padding(.bottom, 40)
      }
      .toast(item: $toast)

      chatButton
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
    }
    .background(Color.gray50)
    .navigationTitle(contact.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        if let viewModel {
          NavigationLink {
            AddContactView(
              existingContact: contact,
              existingGroups: existingGroups,
              onSave: { updatedContact in
                guard viewModel.saveMyContact(updatedContact) else {
                  return false
                }
                showUpdatedToast(originalContact: contact)
                return true
              },
              onDelete: { contactID in
                viewModel.deleteContact(id: contactID)
              },
              onDeleted: onDeleted
            )
          } label: {
            Image(systemName: "pencil")
          }
          .accessibilityLabel("Edit Contact")
        }
      }
    }
    .tint(.gray950)
  }

  private func showUpdatedToast(originalContact: Contact) {
    guard let viewModel else {
      return
    }

    toast = Toast(
      message: "연락처가 수정되었습니다",
      style: .success,
      action: Toast.Action(title: "되돌리기") {
        viewModel.saveMyContact(originalContact)
      }
    )
  }

  private var profileHeader: some View {
    VStack(spacing: 22) {
      profileImage

      VStack(spacing: 8) {
        Text(contact.name)
          .typeStyle(.title1Emphasized)
          .foregroundStyle(.gray950)

        Text(subtitle)
          .typeStyle(.subheadline)
          .foregroundStyle(.gray600)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 14)
          .padding(.vertical, 6)
          .background(.gray100)
          .clipShape(Capsule())
      }
    }
  }

  private var profileImage: some View {
    Group {
      if contact.profileImageData != nil {
        Image(.logo)
          .profileImage(data: contact.profileImageData, size: 136)
      } else {
        RoundedRectangle(cornerRadius: 25.6)
          .fill(.gray100)
          .frame(width: 96, height: 96)
      }
    }
  }

  private var contactInfoCard: some View {
    VStack(alignment: .leading, spacing: 24) {
      profileInfo(label: "이메일", value: displayValue(contact.email))
      profileInfo(label: "전화번호", value: displayValue(ContactPhoneNumberFormatter.displayFormatted(contact.phone)))
      profileInfo(label: "URL", value: displayValue(contact.url), lineLimit: 1)
    }
    .profileCard()
  }

  private var additionalInfoCard: some View {
    VStack(alignment: .leading, spacing: 24) {
      profileInfo(label: "주소", value: displayValue(contact.address))
      profileInfo(label: "생일", value: formattedDate(contact.birthday))
      profileInfo(label: "기념일", value: formattedDate(contact.anniversary))
      socialLinksInfo
    }
    .profileCard()
  }

  private var noteCard: some View {
    profileInfo(label: "한 줄 기록", value: contact.note)
      .profileCard()
  }

  @ViewBuilder
  private var socialLinksInfo: some View {
    if contact.socialLinks.isEmpty {
      profileInfo(label: "소셜 링크", value: "-")
    } else {
      ForEach(contact.socialLinks, id: \.self) { link in
        profileInfo(label: link.platform, value: displayValue(link.handle), lineLimit: 1)
      }
    }
  }

  private func profileInfo(label: String, value: String, lineLimit: Int? = nil) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(label)
        .typeStyle(.footnote)
        .foregroundStyle(.gray400)

      Text(value)
        .typeStyle(.headline)
        .foregroundStyle(.gray800)
        .lineLimit(lineLimit)
        .truncationMode(.tail)
    }
  }

  private var chatButton: some View {
    NavigationLink {
      ChatView(
        contact: contact,
        repository: noteRepository,
        imageAnalyzer: noteImageAnalyzer,
        imageAnalysisRepository: noteImageAnalysisRepository,
        linkPreviewFetcher: linkPreviewFetcher,
        linkPreviewRepository: noteLinkPreviewRepository,
        labelTranslator: labelTranslator
      )
    } label: {
      Text("메모하기")
        .typeStyle(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(.violet500)
        .clipShape(Capsule())
    }
  }

  private func displayValue(_ value: String) -> String {
    value.isEmpty ? "-" : value
  }

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy.MM.dd"
    return formatter
  }()

  private func formattedDate(_ date: Date?) -> String {
    guard let date else {
      return "-"
    }
    return Self.dateFormatter.string(from: date)
  }

  private var subtitle: String {
    displayValue(contact.group)
  }
}

private extension View {
  func profileCard() -> some View {
    self
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(20)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}

#Preview {
  NavigationStack {
    ContactDetailView(
      contact: Contact(
        name: "Sample User",
        role: "Product Designer",
        company: "@syno",
        email: "sample@syno.app",
        phone: "010-0000-0000",
        url: "https://www.linkedin.com/in/syno",
        note: "샘플 연락처 메모"
      ),
      noteRepository: PreviewRepositories.note,
      noteImageAnalyzer: PreviewRepositories.noteImageAnalyzer,
      noteImageAnalysisRepository: PreviewRepositories.noteImageAnalysis,
      linkPreviewFetcher: PreviewRepositories.linkPreviewFetcher,
      noteLinkPreviewRepository: PreviewRepositories.noteLinkPreview,
      labelTranslator: PreviewRepositories.labelTranslator,
      viewModel: nil,
      existingGroups: [],
      onDeleted: {}
    )
  }
}
