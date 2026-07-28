//
//  GroupSelectionSheet.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 연락처 그룹을 임시 선택한 뒤 체크 버튼으로 적용하는 바텀시트입니다.
struct GroupSelectionSheet: View {
  @Environment(\.dismiss) private var dismiss

  /// 시트 안에서만 변경되는 임시 그룹 값입니다.
  @State private var draftGroup: String

  /// 새로 만들 그룹의 임시 입력값입니다.
  @State private var newGroup = ""

  /// 새 그룹 입력 필드 노출 여부입니다.
  @State private var isAddingNewGroup = false

  /// 이번 시트 세션에서 새로 추가해 목록 맨 위에 고정할 그룹입니다.
  @State private var justAddedGroup: String?

  @FocusState private var isNewGroupFieldFocused: Bool

  /// 저장된 연락처에서 수집한 그룹 목록입니다.
  let existingGroups: [String]

  /// 체크 버튼을 눌렀을 때 부모 폼에 선택값을 반영하는 콜백입니다.
  let onApply: (String) -> Void

  /// 방금 추가한 그룹을 제외한, 정렬된 순서로 보여줄 목록입니다.
  private var sortedGroupOptions: [String] {
    groupOptions.filter { $0 != justAddedGroup }
  }

  /// 선택 안 함 항목을 제외한 병합 그룹 목록입니다.
  private var groupOptions: [String] {
    GroupOptions.merged(
      existingGroups: existingGroups,
      draftGroup: draftGroup
    )
  }

  init(
    selectedGroup: String,
    existingGroups: [String] = [],
    onApply: @escaping (String) -> Void
  ) {
    let options = GroupOptions.merged(
      existingGroups: existingGroups,
      draftGroup: selectedGroup
    )
    self.onApply = onApply
    self.existingGroups = existingGroups
    _draftGroup = State(
      initialValue: GroupOptions.matchingGroup(for: selectedGroup, in: options) ?? selectedGroup
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      AddContactSheetHeader(
        title: "그룹 선택",
        onCancel: { dismiss() },
        isApplyEnabled: !draftGroup.isEmpty
      ) {
        onApply(draftGroup)
        dismiss()
      }

      ScrollView {
        VStack(spacing: 8) {
          if let justAddedGroup {
            groupRow(title: justAddedGroup, group: justAddedGroup)
          }

          ForEach(sortedGroupOptions.indices, id: \.self) { index in
            groupRow(title: sortedGroupOptions[index], group: sortedGroupOptions[index])
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
  }

  private func groupRow(title: String, group: String) -> some View {
    let isSelected = draftGroup == group

    return Button {
      draftGroup = isSelected ? "" : group
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
        HStack(spacing: 12) {
          Image(systemName: "plus.circle.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.violet500)

          Text("그룹 추가하기")
            .typeStyle(.calloutEmphasized)
            .foregroundStyle(.violet500)

          Spacer()
        }
        .padding(.horizontal, 20)
        .frame(height: 54)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
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
    let trimmedGroup = newGroup.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedGroup.isEmpty else {
      return
    }

    if let matchedGroup = GroupOptions.matchingGroup(for: trimmedGroup, in: groupOptions) {
      draftGroup = matchedGroup
    } else {
      draftGroup = trimmedGroup
      justAddedGroup = trimmedGroup
    }
    newGroup = ""
    isAddingNewGroup = false
    isNewGroupFieldFocused = false
  }
}

#Preview {
  GroupSelectionSheet(selectedGroup: "커피챗", existingGroups: ["스터디", "Portfolio"]) { _ in }
}
