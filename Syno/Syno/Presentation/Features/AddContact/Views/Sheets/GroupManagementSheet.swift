import SwiftData
import SwiftUI

/// 그룹을 추가·삭제하고 사용자 지정 순서를 변경하는 바텀시트입니다.
struct GroupManagementSheet: View {
  private enum SortMode: String, CaseIterable, Identifiable {
    case alphabetical = "가나다순"
    case custom = "사용자 설정 순"

    var id: String { rawValue }
  }

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \StoredGroup.sortIndex) private var storedGroups: [StoredGroup]

  @State private var newGroup = ""
  @AppStorage("GroupManagementSheet.sortMode") private var sortModeRawValue = SortMode.alphabetical.rawValue
  @State private var groupPendingDeletion: StoredGroup?
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?

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
        ForEach(displayedGroups, id: \.persistentModelID) { group in
          groupRow(group)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .padding(.bottom, 8)
        }
        .onMove(perform: moveGroups)
        .moveDisabled(sortMode != .custom)

        addGroupRow
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .environment(\.editMode, .constant(.active))
      .padding(.horizontal, 16)
    }
    .padding(.top, 16)
    .background(Color.gray50)
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
  }

  private var sortMode: SortMode {
    SortMode(rawValue: sortModeRawValue) ?? .alphabetical
  }

  private var sortModeBinding: Binding<SortMode> {
    Binding(
      get: { sortMode },
      set: { sortModeRawValue = $0.rawValue }
    )
  }

  private var sortPicker: some View {
    Picker("정렬", selection: sortModeBinding) {
      ForEach(SortMode.allCases) { mode in
        Text(mode.rawValue).tag(mode)
      }
    }
    .pickerStyle(.segmented)
  }

  private func groupRow(_ group: StoredGroup) -> some View {
    HStack(spacing: 12) {
      Text(group.name)
        .typeStyle(.callout)
        .foregroundStyle(.gray900)

      Spacer()

      Button {
        groupPendingDeletion = group
        requestDeleteConfirmation()
      } label: {
        Image(systemName: "minus.circle.fill")
          .font(.system(size: 22))
          .foregroundStyle(.gray600)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(group.name) 그룹 삭제")

      Image(systemName: "line.3.horizontal")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.gray600)
        .opacity(sortMode == .custom ? 1 : 0.35)
    }
    .padding(.horizontal, 16)
    .frame(height: 54)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 999))
  }

  private var addGroupRow: some View {
    HStack(spacing: 12) {
      TextField("새 그룹 이름", text: Binding(
        get: { newGroup },
        set: { newGroup = String($0.prefix(20)) }
      ))
      .typeStyle(.callout)
      .submitLabel(.done)
      .onSubmit(addGroup)

      Button(action: addGroup) {
        Image(systemName: "plus.circle.fill")
          .font(.system(size: 22))
          .foregroundStyle(.violet500)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("그룹 추가")
    }
    .padding(.horizontal, 16)
    .frame(height: 54)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 999))
  }

  private func addGroup() {
    do {
      _ = try GroupService(modelContext: modelContext).createGroup(named: newGroup)
      newGroup = ""
    } catch {
      toast = Toast(message: "그룹 추가에 실패했습니다", style: .failure)
    }
  }

  private func moveGroups(from source: IndexSet, to destination: Int) {
    guard sortMode == .custom else {
      return
    }

    var groups = displayedGroups
    groups.move(fromOffsets: source, toOffset: destination)
    do {
      try GroupService(modelContext: modelContext).updateSortIndexes(for: groups)
    } catch {
      toast = Toast(message: "그룹 순서 저장에 실패했습니다", style: .failure)
    }
  }

  private var displayedGroups: [StoredGroup] {
    switch sortMode {
    case .custom:
      storedGroups
    case .alphabetical:
      storedGroups.sorted {
        $0.name.localizedStandardCompare($1.name) == .orderedAscending
      }
    }
  }

  private func requestDeleteConfirmation() {
    guard let groupPendingDeletion else {
      return
    }

    confirmationAlert = DestructiveConfirmationAlert(
      title: "\(groupPendingDeletion.name) 그룹을\n삭제하겠습니까?",
      message: "이 그룹을 사용 중인 연락처는 '선택 안 함'으로 변경됩니다. 이 작업은 되돌릴 수 없습니다."
    ) {
      deletePendingGroup()
    }
  }

  private func deletePendingGroup() {
    guard let groupPendingDeletion else {
      return
    }

    do {
      try GroupService(modelContext: modelContext).deleteGroup(groupPendingDeletion)
      self.groupPendingDeletion = nil
    } catch {
      toast = Toast(message: "그룹 삭제에 실패했습니다", style: .failure)
    }
  }
}

#Preview {
  GroupManagementSheet()
    .modelContainer(for: [StoredGroup.self, StoredContact.self], inMemory: true)
}
