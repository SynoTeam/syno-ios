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

  /// 체크 버튼을 눌렀을 때 부모 폼에 선택값을 반영하는 콜백입니다.
  let onApply: (String) -> Void

  /// 선택 안 함 항목을 포함한 그룹 목록입니다.
  private var groupOptions: [String] {
    [""] + AddContactViewModel.groupOptions
  }

  init(
    selectedGroup: String,
    onApply: @escaping (String) -> Void
  ) {
    self.onApply = onApply
    _draftGroup = State(initialValue: selectedGroup)
  }

  var body: some View {
    VStack(spacing: 0) {
      AddContactSheetHeader(
        title: "그룹 선택",
        onCancel: { dismiss() }
      ) {
        onApply(draftGroup)
        dismiss()
      }

      VStack(spacing: 0) {
        ForEach(groupOptions.indices, id: \.self) { index in
          let group = groupOptions[index]

          Button {
            draftGroup = group
          } label: {
            HStack(spacing: 12) {
              Text(group.isEmpty ? "선택 안 함" : group)
                .typeStyle(.body)
                .foregroundStyle(.gray950)

              Spacer()

              if draftGroup == group {
                Image(systemName: "checkmark")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(.violet500)
              }
            }
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)

          if index < groupOptions.count - 1 {
            Divider()
              .background(.gray50)
              .padding(.horizontal, 20)
          }
        }
      }
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .padding(.horizontal, 16)

      Spacer(minLength: 0)
    }
    .padding(.top, 32)
    .background(Color.gray50)
  }
}

#Preview {
  GroupSelectionSheet(selectedGroup: "커피챗") { _ in }
}
