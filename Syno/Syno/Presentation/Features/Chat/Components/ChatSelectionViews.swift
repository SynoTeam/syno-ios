import SwiftUI

/// 선택 모드에서 입력창 자리에 나타나는 삭제 바입니다.
struct ChatSelectionBar: View {
  let selectedCount: Int
  let onDelete: () -> Void

  var body: some View {
    Button(action: onDelete) {
      Text(selectedCount == 0 ? "삭제" : "삭제 (\(selectedCount))")
        .typeStyle(.calloutEmphasized)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(selectedCount == 0 ? Color.gray300 : Color.errorRed)
        .clipShape(Capsule())
    }
    .disabled(selectedCount == 0)
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(Color.gray50)
    .accessibilityLabel("선택한 메시지 삭제")
  }
}

/// 선택 모드에서 말풍선 오른쪽에 보이는 체크 원입니다. 선택되면 짙은 원 안에 흰 체크가 나타납니다.
struct ChatSelectionIndicator: View {
  let isSelected: Bool

  var body: some View {
    Circle()
      .fill(isSelected ? Color.gray900 : Color.clear)
      .overlay {
        if isSelected {
          Image(.check)
            .resizable()
            .renderingMode(.template)
            .frame(width: 16, height: 16)
            .foregroundStyle(.white)
        } else {
          Circle().stroke(Color.gray300, lineWidth: 1.5)
        }
      }
      .frame(width: 28, height: 28)
      .accessibilityLabel(isSelected ? "선택됨" : "선택 안 됨")
  }
}

/// 말풍선 오른쪽에 체크 원을 붙이는 선택 가능한 줄입니다. 선택 모드에서는 줄 전체가 탭 대상이 됩니다.
/// 선택 모드가 아닐 때는 말풍선의 탭과 미리보기 동작에 영향을 주지 않습니다.
struct ChatSelectableRow<Content: View>: View {
  let isSelectionActive: Bool
  let isSelected: Bool
  let onToggle: () -> Void
  let content: Content

  init(
    isSelectionActive: Bool,
    isSelected: Bool,
    onToggle: @escaping () -> Void,
    @ViewBuilder content: () -> Content
  ) {
    self.isSelectionActive = isSelectionActive
    self.isSelected = isSelected
    self.onToggle = onToggle
    self.content = content()
  }

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      content
        .allowsHitTesting(!isSelectionActive)

      if isSelectionActive {
        ChatSelectionIndicator(isSelected: isSelected)
          .transition(.move(edge: .trailing).combined(with: .opacity))
      }
    }
    .overlay {
      // 선택 모드에서만 줄 전체를 덮어 탭으로 선택을 토글한다. 평소에는 말풍선 동작에 영향을 주지 않는다.
      if isSelectionActive {
        Color.clear
          .contentShape(Rectangle())
          .onTapGesture(perform: onToggle)
      }
    }
    .animation(.snappy(duration: 0.25), value: isSelectionActive)
  }
}
