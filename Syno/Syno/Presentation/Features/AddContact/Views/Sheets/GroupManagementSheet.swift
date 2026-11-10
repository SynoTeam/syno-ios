import SwiftUI

/// 그룹을 삭제하고 사용자 지정 순서를 변경하는 바텀시트입니다.
/// 그룹 추가는 연락처 편집의 그룹 선택 시트에서만 합니다.
struct GroupManagementSheet: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: GroupManagementViewModel
  @State private var groupPendingDeletion: ContactGroup?
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?

  init(groupRepository: any GroupRepository) {
    _viewModel = State(initialValue: GroupManagementViewModel(groupRepository: groupRepository))
  }

  var body: some View {
    VStack(spacing: 0) {
      AddContactSheetHeader(title: "그룹 편집", onCancel: { dismiss() }) {
        dismiss()
      }

      sortPicker
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)

      List {
        ForEach(viewModel.displayedGroups) { group in
          groupRow(group)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            // 흰 알약을 행 배경으로 그려야 시스템 순서 변경 핸들이 알약 안쪽에 들어간다.
            .listRowBackground(Capsule().fill(.white))
        }
        .onMove(perform: viewModel.moveGroups)
        .moveDisabled(!viewModel.canReorder)
      }
      .listStyle(.plain)
      .listRowSpacing(8)
      .scrollContentBackground(.hidden)
      // 사용자 설정 순에서만 편집 모드를 켜서 시스템 순서 변경 핸들을 하나만 보여준다.
      .environment(\.editMode, .constant(viewModel.canReorder ? .active : .inactive))
      .padding(.horizontal, 16)
    }
    .padding(.top, 16)
    .background(Color.gray50)
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
    .onAppear {
      viewModel.load()
    }
    .onChange(of: viewModel.failureMessage) { _, message in
      guard let message else {
        return
      }
      toast = Toast(message: message, style: .failure)
      viewModel.failureMessage = nil
    }
  }

  private var sortPicker: some View {
    Picker("정렬", selection: $viewModel.sortMode) {
      ForEach(GroupManagementViewModel.SortMode.allCases) { mode in
        Text(mode.rawValue).tag(mode)
      }
    }
    .pickerStyle(.segmented)
  }

  private func groupRow(_ group: ContactGroup) -> some View {
    HStack(spacing: 12) {
      Text(group.name)
        .typeStyle(.callout)
        .foregroundStyle(.gray900)

      Spacer()

      Button {
        requestDeleteConfirmation(for: group)
      } label: {
        Image(.minusCircle)
          .resizable()
          .renderingMode(.template)
          .frame(width: 24, height: 24)
          .foregroundStyle(.gray600)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(group.name) 그룹 삭제")
    }
    .padding(.horizontal, 16)
    .frame(height: 54)
  }

  private func requestDeleteConfirmation(for group: ContactGroup) {
    groupPendingDeletion = group
    confirmationAlert = DestructiveConfirmationAlert(
      title: "\(group.name) 그룹을\n삭제하겠습니까?",
      message: "이 그룹을 사용 중인 연락처는 '선택 안 함'으로 변경됩니다. 이 작업은 되돌릴 수 없습니다.",
      acknowledgementText: nil
    ) {
      deletePendingGroup()
    }
  }

  private func deletePendingGroup() {
    guard let groupPendingDeletion else {
      return
    }
    viewModel.deleteGroup(named: groupPendingDeletion.name)
    self.groupPendingDeletion = nil
  }
}

#Preview {
  GroupManagementSheet(groupRepository: PreviewRepositories.appContainer.groupService)
    .previewModelContainer()
}
