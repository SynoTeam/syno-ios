//
//  ContactDetailView.swift
//  Syno
//
//  Created by 이승진 on 7/17/26.
//

import SwiftUI

struct ContactDetailView: View {
  let contact: Contact
  let noteRepository: any NoteRepository
  let noteImageAnalyzer: any NoteImageAnalyzing
  let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  let labelTranslator: any LabelTranslating

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(spacing: 28) {
          profileHeader
          infoCard
        }
        .padding(.horizontal, 22)
        .padding(.top, 28)
        .padding(.bottom, 40)
      }

      chatButton
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
    }
    .background(Color.gray50)
    .navigationTitle(contact.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {} label: {
          Image(systemName: "pencil")
        }
        .accessibilityLabel("Edit Contact")
      }
    }
    .tint(.gray950)
  }

  private var profileHeader: some View {
    VStack(spacing: 22) {
      Image(.logo)
        .profileImage(data: contact.profileImageData, size: 136)

      VStack(spacing: 8) {
        Text(contact.name)
          .typeStyle(.title1)
          .foregroundStyle(.gray950)

        Text(subtitle)
          .typeStyle(.headline)
          .foregroundStyle(.gray500)
          .multilineTextAlignment(.center)
      }
    }
  }

  private var infoCard: some View {
    VStack(alignment: .leading, spacing: 24) {
      profileInfo(label: "이메일", value: displayValue(contact.email))
      profileInfo(label: "연락처", value: displayValue(ContactPhoneNumberFormatter.displayFormatted(contact.phone)))
      profileInfo(label: "링크드인 URL", value: displayValue(contact.linkedInURL), lineLimit: 1)
      profileInfo(label: "그룹", value: displayValue(contact.group))

      if !contact.note.isEmpty {
        profileInfo(label: "한 줄 기록", value: contact.note)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(28)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 22))
  }

  private func profileInfo(label: String, value: String, lineLimit: Int? = nil) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(label)
        .typeStyle(.subheadline)
        .foregroundStyle(.gray400)

      Text(value)
        .typeStyle(.title3)
        .foregroundStyle(.gray950)
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

  private var subtitle: String {
    if !contact.role.isEmpty && !contact.company.isEmpty {
      return "\(contact.role) \(contact.company)"
    }

    if !contact.role.isEmpty {
      return contact.role
    }

    if !contact.email.isEmpty {
      return contact.email
    }

    return "-"
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
        linkedInURL: "https://www.linkedin.com/in/syno",
        note: "샘플 연락처 메모"
      ),
      noteRepository: PreviewRepositories.note,
      noteImageAnalyzer: PreviewRepositories.noteImageAnalyzer,
      noteImageAnalysisRepository: PreviewRepositories.noteImageAnalysis,
      labelTranslator: PreviewRepositories.labelTranslator
    )
  }
}
