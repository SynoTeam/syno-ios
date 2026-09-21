//
//  MyPageView.swift
//  Syno
//
//  Created by 이승진 on 7/16/26.
//

import SwiftUI

/// 내 연락처 정보를 보여주는 프로필 화면입니다.
struct MyPageView: View {
  let contact: Contact
  let noteRepository: any NoteRepository
  let noteImageAnalyzer: any NoteImageAnalyzing
  let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  let linkPreviewFetcher: any NoteLinkPreviewFetching
  let noteLinkPreviewRepository: any NoteLinkPreviewRepository
  let labelTranslator: any LabelTranslating
  let noteVoiceTranscriber: any NoteVoiceTranscribing
  let noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository
  let existingGroups: [String]
  let accountResetService: AccountResetService
  let onSave: (Contact) -> Void

  init(
    contact: Contact = Contact(
      name: "내 프로필",
      role: "",
      company: ""
    ),
    noteRepository: any NoteRepository,
    noteImageAnalyzer: any NoteImageAnalyzing,
    noteImageAnalysisRepository: any NoteImageAnalysisRepository,
    linkPreviewFetcher: any NoteLinkPreviewFetching,
    noteLinkPreviewRepository: any NoteLinkPreviewRepository,
    labelTranslator: any LabelTranslating,
    noteVoiceTranscriber: any NoteVoiceTranscribing,
    noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository,
    existingGroups: [String] = [],
    accountResetService: AccountResetService,
    onSave: @escaping (Contact) -> Void = { _ in }
  ) {
    self.contact = contact
    self.noteRepository = noteRepository
    self.noteImageAnalyzer = noteImageAnalyzer
    self.noteImageAnalysisRepository = noteImageAnalysisRepository
    self.linkPreviewFetcher = linkPreviewFetcher
    self.noteLinkPreviewRepository = noteLinkPreviewRepository
    self.labelTranslator = labelTranslator
    self.noteVoiceTranscriber = noteVoiceTranscriber
    self.noteVoiceTranscriptRepository = noteVoiceTranscriptRepository
    self.existingGroups = existingGroups
    self.accountResetService = accountResetService
    self.onSave = onSave
  }

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(spacing: 20) {
          profileHeader
          contactInfoCard

          if !contact.group.isEmpty {
            groupInfoCard
          }

          if hasAdditionalInfo {
            additionalInfoCard
          }

          if !contact.note.isEmpty {
            noteCard
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 120)
      }

      memoButton
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }
    .background(Color.gray50)
    .navigationTitle(displayName)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        NavigationLink {
          MyPageEditView(
            contact: contact,
            existingGroups: existingGroups,
            onSave: onSave
          )
        } label: {
          Image(systemName: "pencil")
        }
        .accessibilityLabel("Edit My Page")

        NavigationLink {
          SettingsView(accountResetService: accountResetService)
        } label: {
          Image(systemName: "gearshape")
        }
        .accessibilityLabel("Settings")
      }
    }
    .tint(.gray950)
  }

  private var profileHeader: some View {
    VStack(spacing: 22) {
      profileImage

      VStack(spacing: 8) {
        Text(displayName)
          .typeStyle(.callout)
          .foregroundStyle(.gray950)

        Text(subtitle)
          .typeStyle(.footnote)
          .foregroundStyle(.gray500)
          .multilineTextAlignment(.center)
          .lineLimit(2)
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
      profileInfo(icon: .mail, label: "이메일", value: emailText)
      profileInfo(icon: .phone, label: "전화번호", value: phoneText)
      profileInfo(icon: .link, label: "URL", value: urlText, lineLimit: 1)
    }
    .surfaceCard()
  }

  private var groupInfoCard: some View {
    VStack(alignment: .leading, spacing: 24) {
      profileInfo(icon: .person, label: "그룹", value: groupText)
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

  @ViewBuilder
  private var socialLinksInfo: some View {
    ForEach(contact.socialLinks, id: \.self) { link in
      profileInfo(icon: .link, label: link.platform, value: displayValue(link.handle), lineLimit: 1)
    }
  }

  private var noteCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 4) {
        Image(.document)
          .resizable()
          .renderingMode(.template)
          .frame(width: 14, height: 14)
          .foregroundStyle(.gray400)

        Text("한 줄 기록")
          .typeStyle(.caption1)
          .foregroundStyle(.gray400)
      }

      Text(noteText)
        .typeStyle(.caption1)
        .foregroundStyle(.gray950)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .surfaceCard()
  }

  private func profileInfo(icon: ImageResource, label: String, value: String, lineLimit: Int? = nil) -> some View {
    VStack(alignment: .leading, spacing: 6) {
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

      Text(value)
        .typeStyle(.headline)
        .foregroundStyle(.gray800)
        .lineLimit(lineLimit)
        .truncationMode(.tail)
    }
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

  private var memoButton: some View {
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
        voiceTranscriptRepository: noteVoiceTranscriptRepository
      )
    } label: {
      Text("메모하기")
    }
    .buttonStyle(.cta())
  }

  private var displayName: String {
    contact.name.isEmpty ? "내 프로필" : contact.name
  }

  private var emailText: String {
    displayValue(contact.email)
  }

  private var phoneText: String {
    displayValue(ContactPhoneNumberFormatter.displayFormatted(contact.phone))
  }

  private var urlText: String {
    displayValue(contact.url)
  }

  private var groupText: String {
    displayValue(contact.group)
  }

  private var noteText: String {
    displayValue(contact.note)
  }

  private var subtitle: String {
    "My Profile"
  }

  private func displayValue(_ value: String) -> String {
    value.isEmpty ? "-" : value
  }
}

#Preview {
  MyPageView(
    noteRepository: PreviewRepositories.note,
    noteImageAnalyzer: PreviewRepositories.noteImageAnalyzer,
    noteImageAnalysisRepository: PreviewRepositories.noteImageAnalysis,
    linkPreviewFetcher: PreviewRepositories.linkPreviewFetcher,
    noteLinkPreviewRepository: PreviewRepositories.noteLinkPreview,
    labelTranslator: PreviewRepositories.labelTranslator,
    noteVoiceTranscriber: PreviewRepositories.noteVoiceTranscriber,
    noteVoiceTranscriptRepository: PreviewRepositories.noteVoiceTranscript,
    accountResetService: PreviewRepositories.accountReset
  )
}
