import SwiftData
import SwiftUI

/// `StoredGroup`을 단일 소스로 사용해 연락처 그룹을 선택하는 바텀시트입니다.
struct GroupSelectionSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \StoredGroup.sortIndex) private var storedGroups: [StoredGroup]

  @State private var draftGroup: String
  @State private var newGroup = ""
  @State private var isAddingNewGroup = false
  @State private var isShowingGroupManagement = false
  @State private var toast: Toast?
  @FocusState private var isNewGroupFieldFocused: Bool

  let onApply: (String) -> Void

  init(
    selectedGroup: String,
    existingGroups _: [String] = [],
    onApply: @escaping (String) -> Void
  ) {
    _draftGroup = State(initialValue: selectedGroup)
    self.onApply = onApply
  }

  var body: some View {
    VStack(spacing: 0) {
      AddContactSheetHeader(
        title: "그룹 선택",
        onCancel: { dismiss() }
      ) {
        onApply(canonicalGroupName(for: draftGroup))
        dismiss()
      }

      ScrollView {
        VStack(spacing: 8) {
          groupRow(title: "선택 안 함", group: "")

          ForEach(storedGroups, id: \.persistentModelID) { group in
            groupRow(title: group.name, group: group.name)
          }

          addNewGroupRow

          Button("그룹 편집") {
            isShowingGroupManagement = true
          }
          .typeStyle(.subheadline)
          .foregroundStyle(.gray600)
          .frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
      }

      Spacer(minLength: 0)
    }
    .padding(.top, 32)
    .background(Color.gray50)
    .sheet(isPresented: $isShowingGroupManagement) {
      GroupManagementSheet()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    .toast(item: $toast)
  }

  private func groupRow(title: String, group: String) -> some View {
    let isSelected = draftGroup == group

    return Button {
      draftGroup = group
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "checkmark")
          .font(.system(size: 15, weight: .semibold))
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
    if isAddingNewGroup {
      HStack(spacing: 12) {
        TextField("그룹 이름", text: newGroupBinding)
          .typeStyle(.body)
          .foregroundStyle(.gray950)
          .lineLimit(1)
          .focused($isNewGroupFieldFocused)
          .onAppear { isNewGroupFieldFocused = true }
          .submitLabel(.done)
          .onSubmit(confirmNewGroup)

        Button("추가", action: confirmNewGroup)
          .typeStyle(.subheadline)
          .foregroundStyle(.violet500)
          .buttonStyle(.plain)
      }
      .padding(.horizontal, 20)
      .frame(height: 54)
      .frame(maxWidth: .infinity)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 16))
    } else {
      Button {
        isAddingNewGroup = true
        isNewGroupFieldFocused = true
      } label: {
        Label("그룹 추가하기", systemImage: "plus.circle.fill")
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.violet500)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 20)
          .frame(height: 54)
          .background(.white)
          .clipShape(RoundedRectangle(cornerRadius: 16))
      }
      .buttonStyle(.plain)
    }
  }

  private var newGroupBinding: Binding<String> {
    Binding(
      get: { newGroup },
      set: { newGroup = String($0.prefix(20)) }
    )
  }

  private func confirmNewGroup() {
    do {
      let group = try GroupService(modelContext: modelContext).createGroup(named: newGroup)
      if let group {
        draftGroup = group.name
      }
      newGroup = ""
      isAddingNewGroup = false
      isNewGroupFieldFocused = false
    } catch {
      toast = Toast(message: "그룹 추가에 실패했습니다", style: .failure)
    }
  }

  private func canonicalGroupName(for group: String) -> String {
    storedGroups.first {
      $0.name.compare(group, options: .caseInsensitive) == .orderedSame
    }?.name ?? group
  }
}

#Preview {
  GroupSelectionSheet(selectedGroup: "커피챗") { _ in }
    .modelContainer(for: [StoredGroup.self], inMemory: true)
}
