import SwiftUI

/// 연락처 그룹을 고르거나 새 그룹을 만들어 고르는 바텀시트입니다.
struct GroupSelectionSheet: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: GroupSelectionViewModel
  @State private var toast: Toast?
  @FocusState private var isNewGroupFieldFocused: Bool

  let onApply: (String) -> Void

  init(
    selectedGroup: String,
    groupRepository: any GroupRepository,
    onApply: @escaping (String) -> Void
  ) {
    _viewModel = State(
      initialValue: GroupSelectionViewModel(selectedGroup: selectedGroup, groupRepository: groupRepository)
    )
    self.onApply = onApply
  }

  var body: some View {
    VStack(spacing: 0) {
      AddContactSheetHeader(
        title: "그룹 선택",
        onCancel: { dismiss() }
      ) {
        applySelection()
      }

      ScrollView {
        VStack(spacing: 8) {
          groupRow(title: "선택 안 함", group: "")

          ForEach(viewModel.groups) { group in
            groupRow(title: group.name, group: group.name)
          }

          addNewGroupRow
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
      }

      Spacer(minLength: 0)
    }
    .padding(.top, 32)
    .background(Color.gray50)
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

  private func groupRow(title: String, group: String) -> some View {
    let isSelected = viewModel.selectedGroup == group

    return Button {
      viewModel.select(group)
      isNewGroupFieldFocused = false
    } label: {
      HStack(spacing: 8) {
        Image(.check)
          .resizable()
          .renderingMode(.template)
          .frame(width: 20, height: 20)
          .foregroundStyle(.violet500)
          .opacity(isSelected ? 1 : 0)

        Text(title)
          .typeStyle(isSelected ? .calloutEmphasized : .callout)
          .foregroundStyle(.gray900)

        Spacer()
      }
      .padding(.horizontal, 16)
      .frame(height: 54)
      .frame(maxWidth: .infinity)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 999))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var addNewGroupRow: some View {
    if viewModel.isAddingNewGroup {
      HStack(spacing: 12) {
        TextField("그룹 이름", text: $viewModel.newGroupName)
          .typeStyle(.body)
          .foregroundStyle(.gray950)
          .lineLimit(1)
          .focused($isNewGroupFieldFocused)
          .onAppear { isNewGroupFieldFocused = true }
          .submitLabel(.done)
          .onSubmit { confirmNewGroup() }

        Button(action: clearOrCancelNewGroup) {
          Image(.xCircle)
            .resizable()
            .renderingMode(.template)
            .frame(width: 20, height: 20)
            .foregroundStyle(.gray300)
        }
        .buttonStyle(.plain)
        // 입력이 비어 있으면 지울 내용이 없고 입력 행을 닫으므로 동작에 맞게 안내한다.
        .accessibilityLabel(viewModel.newGroupName.isEmpty ? "그룹 추가 취소" : "입력 지우기")
      }
      .padding(.horizontal, 20)
      .frame(height: 54)
      .frame(maxWidth: .infinity)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 9999))
    } else {
      Button {
        viewModel.startAddingGroup()
        isNewGroupFieldFocused = true
      } label: {
        Label("그룹 추가하기", icon: .plusCircle)
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.violet500)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 20)
          .frame(height: 54)
          .background(.white)
          .clipShape(RoundedRectangle(cornerRadius: 9999))
      }
      .buttonStyle(.plain)
    }
  }

  private func clearOrCancelNewGroup() {
    viewModel.clearOrCancelNewGroup()
    if !viewModel.isAddingNewGroup {
      isNewGroupFieldFocused = false
    }
  }

  private func confirmNewGroup() {
    if viewModel.confirmNewGroup() {
      isNewGroupFieldFocused = false
    }
  }

  /// 새 그룹을 입력하던 중에 상단 완료를 눌러도 그 그룹을 만들어 선택하고 닫습니다.
  private func applySelection() {
    guard let group = viewModel.apply() else {
      return
    }
    onApply(group)
    dismiss()
  }
}

#Preview {
  GroupSelectionSheet(
    selectedGroup: "커피챗",
    groupRepository: PreviewRepositories.appContainer.groupService
  ) { _ in }
    .previewModelContainer()
}
