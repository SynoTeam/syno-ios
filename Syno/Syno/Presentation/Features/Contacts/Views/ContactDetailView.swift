//
//  ContactDetailView.swift
//  Syno
//
//  Created by 이승진 on 7/17/26.
//

import SwiftUI

struct ContactDetailView: View {
  @Environment(\.analytics) private var analytics
  @State private var toast: Toast?

  /// 푸시된 뒤에도 편집 저장 결과가 바로 보이도록 화면이 직접 들고 있는 연락처입니다.
  @State private var contact: Contact
  let noteRepository: any NoteRepository
  let noteImageAnalyzer: any NoteImageAnalyzing
  let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  let linkPreviewFetcher: any NoteLinkPreviewFetching
  let noteLinkPreviewRepository: any NoteLinkPreviewRepository
  let labelTranslator: any LabelTranslating
  let noteVoiceTranscriber: any NoteVoiceTranscribing
  let noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository
  let viewModel: ContactsViewModel?
  let existingGroups: [String]
  let onDeleted: () -> Void

  init(
    contact: Contact,
    noteRepository: any NoteRepository,
    noteImageAnalyzer: any NoteImageAnalyzing,
    noteImageAnalysisRepository: any NoteImageAnalysisRepository,
    linkPreviewFetcher: any NoteLinkPreviewFetching,
    noteLinkPreviewRepository: any NoteLinkPreviewRepository,
    labelTranslator: any LabelTranslating,
    noteVoiceTranscriber: any NoteVoiceTranscribing,
    noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository,
    viewModel: ContactsViewModel?,
    existingGroups: [String],
    onDeleted: @escaping () -> Void
  ) {
    _contact = State(initialValue: contact)
    self.noteRepository = noteRepository
    self.noteImageAnalyzer = noteImageAnalyzer
    self.noteImageAnalysisRepository = noteImageAnalysisRepository
    self.linkPreviewFetcher = linkPreviewFetcher
    self.noteLinkPreviewRepository = noteLinkPreviewRepository
    self.labelTranslator = labelTranslator
    self.noteVoiceTranscriber = noteVoiceTranscriber
    self.noteVoiceTranscriptRepository = noteVoiceTranscriptRepository
    self.viewModel = viewModel
    self.existingGroups = existingGroups
    self.onDeleted = onDeleted
  }

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(spacing: 20) {
          profileHeader
          contactInfoCard

          if hasAdditionalInfo {
            additionalInfoCard
          }

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
                let originalContact = contact
                contact = updatedContact
                showUpdatedToast(originalContact: originalContact)
                return true
              },
              onDelete: { contactID in
                viewModel.deleteContact(id: contactID)
              },
              onDeleted: onDeleted
            )
          } label: {
            Image(.edit)
              .renderingMode(.template)
          }
          .accessibilityLabel("Edit Contact")
        }
      }
    }
    .tint(.gray950)
    .trackScreen("contact_detail")
  }

  private func showUpdatedToast(originalContact: Contact) {
    guard let viewModel else {
      return
    }

    toast = Toast(
      message: "연락처가 수정되었습니다",
      style: .success,
      action: Toast.Action(title: "되돌리기") {
        if viewModel.saveMyContact(originalContact) {
          contact = originalContact
        }
      }
    )
  }

  private var profileHeader: some View {
    VStack(spacing: 22) {
      profileImage

      VStack(spacing: 8) {
        Text(contact.name)
          .typeStyle(.title1Emphasized)
          .foregroundStyle(.bgBlack)

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
        InitialAvatar(name: contact.name, size: 96, cornerRadius: 25.6)
      }
    }
  }

  private var contactInfoCard: some View {
    VStack(alignment: .leading, spacing: 24) {
      profileInfo(
        icon: .mail,
        label: "이메일",
        value: displayValue(contact.email),
        destination: ContactLinkURL.email(contact.email)
      )
      profileInfo(
        icon: .phone,
        label: "전화번호",
        value: displayValue(ContactPhoneNumberFormatter.displayFormatted(contact.phone)),
        destination: ContactLinkURL.phone(contact.phone)
      )
      profileInfo(
        icon: .link,
        label: "URL",
        value: displayValue(contact.url),
        lineLimit: 1,
        destination: ContactLinkURL.website(contact.url)
      )
    }
    .surfaceCard()
  }

  private var hasAdditionalInfo: Bool {
    !contact.address.isEmpty
      || contact.birthday != nil
      || contact.anniversary != nil
      || !contact.socialLinks.isEmpty
  }

  private var additionalInfoCard: some View {
    VStack(alignment: .leading, spacing: 24) {
      if !contact.address.isEmpty {
        profileInfo(icon: .location, label: "주소", value: contact.address)
      }
      if let birthday = contact.birthday {
        profileInfo(icon: .calendar, label: "생일", value: formattedDate(birthday))
      }
      if let anniversary = contact.anniversary {
        profileInfo(icon: .calendar, label: "기념일", value: formattedDate(anniversary))
      }
      socialLinksInfo
    }
    .surfaceCard()
  }

  private var noteCard: some View {
    profileInfo(icon: .document, label: "한 줄 기록", value: contact.note)
      .surfaceCard()
  }

  @ViewBuilder
  private var socialLinksInfo: some View {
    ForEach(contact.socialLinks, id: \.self) { link in
      profileInfo(icon: .link, label: link.platform, value: displayValue(link.handle), lineLimit: 1)
    }
  }

  private func profileInfo(
    icon: ImageResource,
    label: String,
    value: String,
    lineLimit: Int? = nil,
    destination: URL? = nil
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 4) {
        Image(icon)
          .resizable()
          .renderingMode(.template)
          .frame(width: 14, height: 14)
          .foregroundStyle(.gray400)

        Text(label)
          .typeStyle(.footnote)
          .foregroundStyle(.gray400)
      }

      if let destination {
        Link(destination: destination) {
          profileValueText(value, lineLimit: lineLimit)
        }
      } else {
        profileValueText(value, lineLimit: lineLimit)
      }
    }
  }

  private func profileValueText(_ value: String, lineLimit: Int?) -> some View {
    Text(value)
      .typeStyle(.headline)
      .foregroundStyle(.gray800)
      .lineLimit(lineLimit)
      .truncationMode(.tail)
      .multilineTextAlignment(.leading)
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
        labelTranslator: labelTranslator,
        voiceTranscriber: noteVoiceTranscriber,
        voiceTranscriptRepository: noteVoiceTranscriptRepository,
        analytics: analytics
      )
    } label: {
      Text("메모하기")
    }
    .buttonStyle(.cta())
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
      noteVoiceTranscriber: PreviewRepositories.noteVoiceTranscriber,
      noteVoiceTranscriptRepository: PreviewRepositories.noteVoiceTranscript,
      viewModel: nil,
      existingGroups: [],
      onDeleted: {}
    )
  }
}
