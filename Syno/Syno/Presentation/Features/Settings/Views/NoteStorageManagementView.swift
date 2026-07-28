//
//  NoteStorageManagementView.swift
//  Syno
//
//  Created by Codex on 7/28/26.
//

import SwiftUI

/// 노트 원본 이미지 데이터의 전체 및 연락처별 삭제를 관리하는 시트입니다.
struct NoteStorageManagementView: View {
  @Environment(\.dismiss) private var dismiss

  let accountResetService: AccountResetService

  @State private var totalUsage = "-"
  @State private var mediaUsages: [(contact: Contact, bytes: Int64)] = []
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?
  @State private var isDeleting = false

  var body: some View {
    VStack(spacing: 0) {
      AddContactSheetHeader(
        title: "노트 저장공간 관리",
        onCancel: { dismiss() },
        onApply: { dismiss() }
      )

      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          allMediaSection
          contactMediaSection
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 32)
      }
    }
    .padding(.top, 16)
    .background(Color.gray50)
    .task { refreshUsage() }
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
    .overlay {
      if isDeleting {
        DeletionLoadingOverlay()
      }
    }
  }

  private var allMediaSection: some View {
    settingsCard(title: "미디어 데이터 삭제") {
      Text("미디어 데이터는 글을 제외한 사진, 동영상, 음성, 파일을 의미합니다. iCloud에 백업되지 않은 데이터는 복구할 수 없습니다.")
        .typeStyle(.caption1)
        .foregroundStyle(.gray500)
        .fixedSize(horizontal: false, vertical: true)

      Button {
        requestConfirmation(for: .allMedia(contactCount: mediaUsages.count))
      } label: {
        Text("전체 미디어 데이터 삭제 (\(totalUsage))")
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.gray600)
          .frame(maxWidth: .infinity, minHeight: 45)
          .background(.gray100)
          .clipShape(RoundedRectangle(cornerRadius: 999, style: .continuous))
      }
      .buttonStyle(.plain)
      .padding(.top, 12)
    }
  }

  @ViewBuilder
  private var contactMediaSection: some View {
    settingsCard(title: "연락처 데이터 삭제") {
      if mediaUsages.isEmpty {
        Text("삭제할 연락처별 미디어 데이터가 없습니다.")
          .typeStyle(.caption1)
          .foregroundStyle(.gray500)
      } else {
        ForEach(mediaUsages.indices, id: \.self) { index in
          let usage = mediaUsages[index]

          Button {
            requestConfirmation(for: .contact(usage.contact, usage.bytes))
          } label: {
            HStack(spacing: 12) {
              Image(.logo)
                .profileImage(data: usage.contact.profileImageData, size: 44)

              Text(usage.contact.name)
                .typeStyle(.callout)
                .foregroundStyle(.gray950)
                .lineLimit(1)

              Spacer()

              Text(accountResetService.formattedStorageUsage(for: usage.bytes))
                .typeStyle(.subheadline)
                .foregroundStyle(.gray500)
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private func settingsCard<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .typeStyle(.calloutEmphasized)
        .foregroundStyle(.gray800)

      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
  }

  private func requestConfirmation(for action: MediaDeletionAction) {
    confirmationAlert = DestructiveConfirmationAlert(
      title: action.title,
      message: action.message,
      acknowledgementText: nil,
      confirmTitle: "삭제"
    ) {
      perform(action)
    }
  }

  private func perform(_ action: MediaDeletionAction) {
    isDeleting = true

    Task { @MainActor in
      defer { isDeleting = false }

      do {
        try await Task.sleep(for: .milliseconds(1200))

        switch action {
        case .allMedia:
          try accountResetService.deleteAllNoteMedia()
          toast = Toast(message: "전체 미디어 데이터가 삭제되었습니다", style: .success)
        case let .contact(contact, _):
          try accountResetService.deleteNoteMedia(forContactId: contact.id)
          toast = Toast(message: "해당 연락처 노트 삭제되었습니다", style: .success)
        }
        refreshUsage()
      } catch {
        toast = Toast(message: "미디어 데이터를 삭제하지 못했습니다. 다시 시도해주세요.", style: .failure)
      }
    }
  }

  private func refreshUsage() {
    totalUsage = (try? accountResetService.formattedStorageUsage()) ?? "-"
    mediaUsages = (try? accountResetService.mediaUsageByContact()) ?? []
  }
}

private enum MediaDeletionAction {
  case allMedia(contactCount: Int)
  case contact(Contact, Int64)

  var title: String {
    switch self {
    case .allMedia:
      "전체 미디어 데이터를\n삭제하겠습니까?"
    case .contact:
      "해당 연락처의 미디어 데이터를\n모두 삭제하겠습니까?"
    }
  }

  var message: String {
    switch self {
    case let .allMedia(contactCount):
      "전체 \(contactCount)개 연락처의 미디어 데이터를 삭제합니다. iCloud에 백업되지 않는 데이터는 복원 할 수 없습니다."
    case .contact:
      "글 메모를 제외한 모든 미디어 데이터 (사진, 동영상, 음성, 파일)이 삭제됩니다. 이 작업은 되돌릴 수 없습니다."
    }
  }
}

#Preview {
  NoteStorageManagementView(accountResetService: PreviewRepositories.accountReset)
}
