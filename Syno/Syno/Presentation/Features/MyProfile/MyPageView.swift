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
  let labelTranslator: any LabelTranslating
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
    labelTranslator: any LabelTranslating,
    existingGroups: [String] = [],
    accountResetService: AccountResetService,
    onSave: @escaping (Contact) -> Void = { _ in }
  ) {
    self.contact = contact
    self.noteRepository = noteRepository
    self.noteImageAnalyzer = noteImageAnalyzer
    self.noteImageAnalysisRepository = noteImageAnalysisRepository
    self.labelTranslator = labelTranslator
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
          groupInfoCard
          noteCard
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
      profileInfo(label: "이메일", value: emailText)
      profileInfo(label: "전화번호", value: phoneText)
      profileInfo(label: "URL", value: urlText, lineLimit: 1)
    }
    .profileCard()
  }

  private var groupInfoCard: some View {
    VStack(alignment: .leading, spacing: 24) {
      profileInfo(label: "그룹", value: groupText)
    }
    .profileCard()
  }

  private var noteCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("한 줄 기록")
        .typeStyle(.caption1)
        .foregroundStyle(.gray400)

      Text(noteText)
        .typeStyle(.caption1)
        .foregroundStyle(.gray950)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .profileCard()
  }

  private func profileInfo(label: String, value: String, lineLimit: Int? = nil) -> some View {
    VStack(alignment: .leading, spacing: 6) {
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

  private var memoButton: some View {
    NavigationLink {
      ChatView(
        contact: contact,
        repository: noteRepository,
        imageAnalyzer: noteImageAnalyzer,
        imageAnalysisRepository: noteImageAnalysisRepository,
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
  MyPageView(
    noteRepository: PreviewRepositories.note,
    noteImageAnalyzer: PreviewRepositories.noteImageAnalyzer,
    noteImageAnalysisRepository: PreviewRepositories.noteImageAnalysis,
    labelTranslator: PreviewRepositories.labelTranslator,
    accountResetService: PreviewRepositories.accountReset
  )
}
