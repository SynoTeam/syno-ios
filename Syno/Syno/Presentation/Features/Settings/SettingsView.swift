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

  @Environment(\.analytics) private var analytics
  @State private var storageUsage = "-"
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?
  @State private var isDeleting = false
  @State private var loadingMessage = "삭제 중"
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
    .synoBackButton()
    .toolbar(.hidden, for: .tabBar)
    .task { refreshStorageUsage() }
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
    .overlay {
      if isDeleting {
        DeletionLoadingOverlay(message: loadingMessage)
      }
    }
    .sheet(isPresented: $isShowingStorageSheet, onDismiss: refreshStorageUsage) {
      NoteStorageManagementView(accountResetService: accountResetService)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
    .trackScreen("settings")
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
      navigationRow(title: "서비스 이용약관") {
        LegalDocumentView(title: "서비스 이용약관", content: Constants.AppInfo.termsOfService)
      }
      navigationRow(title: "개인정보 처리방침") {
        LegalDocumentView(title: "개인정보 처리방침", content: Constants.AppInfo.privacyPolicy)
      }
      infoRow(title: "현재 버전", value: appVersion)
    }
  }

  private var accountSection: some View {
    settingsCard(title: nil) {
      Button {
        requestConfirmation(for: .dataReset)
      } label: {
        HStack {
          Text("데이터 초기화")
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

  private func navigationRow<Destination: View>(
    title: String,
    @ViewBuilder destination: () -> Destination
  ) -> some View {
    NavigationLink {
      destination()
    } label: {
      HStack(spacing: 12) {
        Text(title)
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.gray800)

        Spacer()

        Image(.chevronRight)
          .resizable()
          .renderingMode(.template)
          .frame(width: 16, height: 16)
          .foregroundStyle(.gray300)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
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
    loadingMessage = action.loadingMessage
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
          analytics.track(
            AnalyticsEvent.accountDataReset,
            properties: [AnalyticsEvent.Property.resetType: "temporary"]
          )
        case .dataReset:
          try accountResetService.resetAllData()
          // 삭제가 iCloud로 다 올라간 다음에 초기화를 마쳐야, 나중에 다시 들어왔을 때
          // 덜 지워진 채로 서버에 남아있던 데이터가 되살아나는 걸 막을 수 있습니다.
          await accountResetService.waitForPendingCloudKitExport()
          // 기존 통계와 이어지도록 이벤트 값은 예전 이름(logout)을 유지한다.
          analytics.track(
            AnalyticsEvent.accountDataReset,
            properties: [AnalyticsEvent.Property.resetType: "logout"]
          )
          analytics.resetIdentity()
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
  /// 이 기기와 iCloud의 모든 데이터를 지웁니다. 앱에 로그인이 없으므로 "로그아웃"이라고 부르지 않습니다 (#130).
  case dataReset

  var title: String {
    switch self {
    case .temporaryData:
      "임시 데이터를 삭제하겠습니까?"
    case .dataReset:
      "데이터를 초기화하시겠습니까?"
    }
  }

  var message: String {
    switch self {
    case .temporaryData:
      "캐시에 임시 저장된 기타 데이터를 삭제하고 정리합니다. 노트 내 텍스트, 사진, 동영상, 음성메시지 파일은 그대로 유지됩니다."
    case .dataReset:
      "이 기기와 iCloud에 저장된 연락처, 노트, 그룹, 내 프로필 등 Syno의 모든 데이터가 삭제됩니다. 같은 iCloud 계정을 쓰는 다른 기기에서도 삭제되며, 되돌릴 수 없습니다."
    }
  }

  var confirmTitle: String {
    switch self {
    case .temporaryData:
      "삭제"
    case .dataReset:
      "초기화"
    }
  }

  var loadingMessage: String {
    switch self {
    case .temporaryData:
      "삭제 중"
    case .dataReset:
      "초기화 중"
    }
  }
}

#Preview {
  SettingsView(accountResetService: PreviewRepositories.accountReset)
}
