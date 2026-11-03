//
//  ContactDetailView.swift
//  Syno
//
//  Created by 이승진 on 7/17/26.
//

import SwiftUI

struct ContactDetailView: View {
  @Environment(\.analytics) private var analytics
  @Environment(\.openURL) private var openURL
  @State private var toast: Toast?
  @State private var isShowingEdit = false
  @State private var confirmationAlert: DestructiveConfirmationAlert?

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
    .synoBackButton()
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        if viewModel != nil {
          Menu {
            Button {
              isShowingEdit = true
            } label: {
              Label("편집하기", icon: .edit)
            }

            Button(role: .destructive) {
              requestDeleteConfirmation()
            } label: {
              // 메뉴가 에셋 아이콘에는 빨간색을 입히지 않아서, 색을 이미지에 직접 입혀 글자와 맞춘다.
              Label {
                Text("삭제하기")
              } icon: {
                Image(uiImage: Self.destructiveTrashIcon)
              }
            }
          } label: {
            Image(.moreHorizontal)
              .renderingMode(.template)
          }
          .accessibilityLabel("More")
        }
      }
    }
    .navigationDestination(isPresented: $isShowingEdit) {
      if let viewModel {
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
          }
        )
      }
    }
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .tint(.gray950)
    .trackScreen("contact_detail")
  }

  /// 삭제 메뉴 항목에 쓰는 빨간색 휴지통 아이콘입니다.
  private static let destructiveTrashIcon = UIImage(resource: .trash)
    .withTintColor(UIColor(Color.errorRed), renderingMode: .alwaysOriginal)

  private func requestDeleteConfirmation() {
    confirmationAlert = DestructiveConfirmationAlert(
      title: "해당 연락처를\n영구적으로 삭제하겠습니까?",
      message: "연락처와 모든 노트와 파일이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.",
      acknowledgementText: nil
    ) {
      deleteContact()
    }
  }

  private func deleteContact() {
    guard let viewModel else {
      return
    }

    guard viewModel.deleteContact(id: contact.id) else {
      toast = Toast(
        message: "연락처 삭제 실패하였습니다",
        style: .failure,
        action: Toast.Action(title: "다시 시도") {
          deleteContact()
        }
      )
      return
    }

    analytics.track(AnalyticsEvent.contactDeleted)
    onDeleted()
  }

  /// 값을 클립보드에 복사하고 복사됐다는 토스트를 보여줍니다.
  private func copy(_ value: String, message: String) {
    UIPasteboard.general.string = value
    toast = Toast(message: message, style: .success, icon: .copy)
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
      if
        let data = contact.profileImageData,
        let uiImage = UIImage(data: data)
      {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 96, height: 96)
          .clipShape(RoundedRectangle(cornerRadius: 25.6, style: .continuous))
      } else {
        InitialAvatar(name: contact.name, size: 96, cornerRadius: 25.6)
      }
    }
  }

  private var contactInfoCard: some View {
    VStack(alignment: .leading, spacing: 24) {
      profileInfo(
        icon: .phone,
        label: "전화번호",
        value: displayValue(ContactPhoneNumberFormatter.displayFormatted(contact.phone)),
        valueAction: .phone(contact.phone)
      )
      profileInfo(
        icon: .mail,
        label: "이메일",
        value: displayValue(contact.email),
        valueAction: .email(contact.email)
      )
      profileInfo(
        icon: .link,
        label: "URL",
        value: displayValue(contact.url),
        lineLimit: 1,
        valueAction: .link(contact.url)
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
    profileInfo(icon: .file, label: "한 줄 기록", value: contact.note, valueStyle: .note)
      .surfaceCard()
  }

  @ViewBuilder
  private var socialLinksInfo: some View {
    ForEach(contact.socialLinks, id: \.self) { link in
      profileInfo(
        icon: .link,
        label: link.platform,
        value: displayValue(link.handle),
        lineLimit: 1,
        valueAction: .link(link.handle)
      )
    }
  }

  /// 값을 눌렀을 때의 동작입니다.
  private enum ValueAction {
    case none
    /// 이메일 보내기와 복사 중에서 고릅니다.
    case email(String)
    /// 전화 걸기와 복사 중에서 고릅니다.
    case phone(String)
    /// 메뉴 없이 바로 복사합니다.
    case link(String)
  }

  /// 값 글자의 스타일입니다.
  private enum ValueStyle {
    case standard
    case note
  }

  private func profileInfo(
    icon: ImageResource,
    label: String,
    value: String,
    lineLimit: Int? = nil,
    valueStyle: ValueStyle = .standard,
    valueAction: ValueAction = .none
  ) -> some View {
    // 값 글자만이 아니라 아이콘·제목·값을 모두 포함한 영역 전체가 눌리도록 하나로 묶는다.
    let content = VStack(alignment: .leading, spacing: 10) {
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

      profileValueText(value, lineLimit: lineLimit, style: valueStyle)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())

    return interactive(content, action: valueAction)
  }

  /// 영역을 눌렀을 때의 동작을 붙입니다. 동작이 없거나 값이 비어 있으면 그대로 보여줍니다.
  @ViewBuilder
  private func interactive(_ content: some View, action: ValueAction) -> some View {
    switch action {
    case .none:
      content
    case let .email(raw):
      copyMenu(
        content,
        raw: raw,
        openURL: ContactLinkURL.email(raw),
        openTitle: "보내기",
        openIcon: .mail,
        copyMessage: "이메일 복사되었습니다"
      )
    case let .phone(raw):
      copyMenu(
        content,
        raw: raw,
        openURL: ContactLinkURL.phone(raw),
        openTitle: "전화",
        openIcon: .phone,
        copyMessage: "전화번호 복사되었습니다"
      )
    case let .link(raw):
      if raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        content
      } else {
        Button {
          copy(raw, message: "링크 복사되었습니다")
        } label: {
          content
        }
        .buttonStyle(.plain)
      }
    }
  }

  /// 값이 있으면 복사 메뉴를 항상 보여주고, 열 수 있는 URL이 있을 때만 실행 항목을 함께 보여줍니다.
  /// 형식이 맞지 않아 URL을 만들 수 없는 값도 복사할 수 있어야 합니다.
  @ViewBuilder
  private func copyMenu(
    _ content: some View,
    raw: String,
    openURL url: URL?,
    openTitle: String,
    openIcon: ImageResource,
    copyMessage: String
  ) -> some View {
    if raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      content
    } else {
      Menu {
        if let url {
          ControlGroup {
            Button {
              openURL(url)
            } label: {
              Label(openTitle, icon: openIcon)
            }

            Button {
              copy(raw, message: copyMessage)
            } label: {
              Label("복사", icon: .copy)
            }
          }
        } else {
          Button {
            copy(raw, message: copyMessage)
          } label: {
            Label("복사", icon: .copy)
          }
        }
      } label: {
        content
      }
    }
  }

  private func profileValueText(_ value: String, lineLimit: Int?, style: ValueStyle) -> some View {
    Text(value)
      .typeStyle(style == .note ? .footnote : .headline)
      .foregroundStyle(style == .note ? .gray400 : .gray800)
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
