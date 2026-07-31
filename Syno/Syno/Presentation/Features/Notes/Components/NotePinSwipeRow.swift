import SwiftUI

/// 노트 행을 스와이프해 핀 상태를 변경할 수 있게 하는 컨테이너입니다.
struct NotePinSwipeRow<Content: View>: View {
  private let actionWidth: CGFloat = 48
  private let actionSpacing: CGFloat = 8
  let isPinned: Bool
  let onTogglePin: () -> Void
  private let label: () -> Content

  @State private var restingOffset: CGFloat = 0
  @GestureState private var dragOffset: CGFloat = 0

  init(
    isPinned: Bool,
    onTogglePin: @escaping () -> Void,
    @ViewBuilder label: @escaping () -> Content
  ) {
    self.isPinned = isPinned
    self.onTogglePin = onTogglePin
    self.label = label
  }

  var body: some View {
    ZStack(alignment: .leading) {
      pinButton

      label()
        .contentShape(Rectangle())
        .offset(x: displayedOffset)
        .highPriorityGesture(swipeGesture)
    }
    .clipped()
    .animation(.snappy(duration: 0.2), value: restingOffset)
    .onChange(of: isPinned) { _, _ in
      restingOffset = 0
    }
    .accessibilityAction(named: isPinned ? "핀 해제" : "핀 추가") {
      onTogglePin()
    }
  }

  private var pinButton: some View {
    Button {
      withAnimation {
        restingOffset = 0
      }
      onTogglePin()
    } label: {
      Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(isPinned ? .violet500 : .gray500)
        .frame(width: actionWidth, height: actionWidth)
        .background(isPinned ? .violet100 : .gray100)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .padding(.trailing, actionSpacing)
    .accessibilityLabel(isPinned ? "핀 해제" : "핀 추가")
  }

  private var revealDistance: CGFloat {
    actionWidth + actionSpacing
  }

  private var displayedOffset: CGFloat {
    max(0, min(revealDistance, restingOffset + dragOffset))
  }

  private var swipeGesture: some Gesture {
    DragGesture(minimumDistance: 12)
      .updating($dragOffset) { value, state, _ in
        guard abs(value.translation.width) > abs(value.translation.height) else {
          return
        }
        state = value.translation.width
      }
      .onEnded { value in
        guard abs(value.translation.width) > abs(value.translation.height) else {
          return
        }

        let proposedOffset = restingOffset + value.predictedEndTranslation.width
        withAnimation {
          restingOffset = proposedOffset > revealDistance / 2 ? revealDistance : 0
        }
      }
  }
}
