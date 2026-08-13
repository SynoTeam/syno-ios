//
//  SettingsView.swift
//  Syno
//
//  Created by 이승진 on 7/14/26.
//

import SwiftUI

/// 계정 데이터와 앱 정보를 관리하는 설정 화면입니다.
struct SettingsView: View {
  let accountResetService: AccountResetService

  @State private var storageUsage = "-"
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?
  @State private var isDeleting = false
  @State private var isShowingStorageSheet = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        dataSection
        appInfoSection
        accountSection
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
    }
    .background(Color.gray50)
    .navigationTitle("앱 설정")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .task { refreshStorageUsage() }
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
    .overlay {
      if isDeleting {
        DeletionLoadingOverlay()
      }
    }
    .sheet(isPresented: $isShowingStorageSheet, onDismiss: refreshStorageUsage) {
      NoteStorageManagementView(accountResetService: accountResetService)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
  }

  private var dataSection: some View {
    settingsCard(title: "데이터 및 저장공간") {
      Button {
        isShowingStorageSheet = true
      } label: {
        infoRow(title: "노트 저장공간 관리", value: storageUsage)
      }
      .buttonStyle(.plain)

      actionRow(title: "임시 데이터 저장", actionTitle: "삭제") {
        requestConfirmation(for: .temporaryData)
      }
    }
  }

  private var appInfoSection: some View {
    settingsCard(title: "앱 정보") {
      infoRow(title: "약관 및 정책", value: "준비 중")
      infoRow(title: "현재 버전", value: appVersion)
    }
  }

  private var accountSection: some View {
    settingsCard(title: nil) {
      Button {
        requestConfirmation(for: .logout)
      } label: {
        HStack {
          Text("로그아웃")
            .typeStyle(.callout)
            .foregroundStyle(.errorRed)

          Spacer()
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }

  private func settingsCard<Content: View>(
    title: String?,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 32) {
      if let title {
        Text(title)
          .typeStyle(.footnote)
          .foregroundStyle(.gray500)
      }

      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  private func infoRow(title: String, value: String) -> some View {
    HStack(spacing: 12) {
      Text(title)
        .typeStyle(.calloutEmphasized)
        .foregroundStyle(.gray800)

      Spacer()

      Text(value)
        .typeStyle(.callout)
        .foregroundStyle(.gray400)
    }
    .contentShape(Rectangle())
  }

  private func actionRow(title: String, actionTitle: String, action: @escaping () -> Void) -> some View {
    HStack(spacing: 12) {
      Text(title)
        .typeStyle(.calloutEmphasized)
        .foregroundStyle(.gray800)

      Spacer()

      Button(actionTitle, action: action)
        .typeStyle(.subheadlineEmphasized)
        .foregroundStyle(.errorRed)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bgError01)
        .clipShape(Capsule())
        .buttonStyle(.plain)
    }
  }

  private var appVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
  }

  private func requestConfirmation(for action: SettingsAction) {
    confirmationAlert = DestructiveConfirmationAlert(
      title: action.title,
      message: action.message,
      acknowledgementText: nil,
      confirmTitle: action.confirmTitle
    ) {
      perform(action)
    }
  }

  private func perform(_ action: SettingsAction) {
    isDeleting = true

    Task { @MainActor in
      defer { isDeleting = false }

      do {
        try await Task.sleep(for: .milliseconds(1200))

        switch action {
        case .temporaryData:
          try accountResetService.clearTemporaryData()
          refreshStorageUsage()
          toast = Toast(message: "임시 데이터가 삭제되었습니다", style: .success)
        case .logout:
          try accountResetService.resetAllData()
          // 삭제가 iCloud로 다 올라간 다음에 로그아웃을 마쳐야, 나중에 다시 들어왔을 때
          // 덜 지워진 채로 서버에 남아있던 데이터가 되살아나는 걸 막을 수 있습니다.
          await accountResetService.waitForPendingCloudKitExport()
        }
      } catch {
        toast = Toast(message: "데이터를 삭제하지 못했습니다. 다시 시도해주세요.", style: .failure)
      }
    }
  }

  private func refreshStorageUsage() {
    storageUsage = (try? accountResetService.formattedStorageUsage()) ?? "-"
  }
}

private enum SettingsAction {
  case temporaryData
  case logout

  var title: String {
    switch self {
    case .temporaryData:
      "임시 데이터를 삭제하겠습니까?"
    case .logout:
      "로그아웃 하시겠습니까?"
    }
  }

  var message: String {
    switch self {
    case .temporaryData:
      "캐시에 임시 저장된 기타 데이터를 삭제하고 정리합니다. 노트 내 텍스트, 사진, 동영상, 음성메시지 파일은 그대로 유지됩니다."
    case .logout:
      ""
    }
  }

  var confirmTitle: String {
    switch self {
    case .temporaryData:
      "삭제"
    case .logout:
      "로그아웃"
    }
  }
}

#Preview {
  SettingsView(accountResetService: PreviewRepositories.accountReset)
}
