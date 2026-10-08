import SwiftUI

/// 한 시점에 열려 있는 노트 스와이프 행과 열린 방향입니다.
struct OpenNoteSwipe: Equatable {
  enum Edge: Equatable {
    /// 행이 오른쪽으로 밀려 왼쪽의 핀 버튼이 보이는 상태
    case pin
    /// 행이 왼쪽으로 밀려 오른쪽의 삭제 버튼이 보이는 상태
    case delete
  }

  let id: Note.ID
  let edge: Edge
}

/// 스와이프 행이 열리고 닫힐 때 쓰는 정착 애니메이션입니다.
private let noteSwipeSettleAnimation = Animation.spring(response: 0.3, dampingFraction: 0.88)

/// 노트 행을 스와이프해 핀 상태를 변경하거나 삭제할 수 있게 하는 컨테이너입니다.
///
/// 오른쪽으로 밀면 핀 버튼, 왼쪽으로 밀면 삭제 버튼이 나타납니다. 열린 행은 부모가
/// `openSwipe`로 관리하므로 한 번에 한 행만 열립니다.
struct NotePinSwipeRow<Content: View>: View {
  private enum DragAxis {
    case horizontal
    case vertical
  }

  private let actionWidth: CGFloat = 40
  private let actionSpacing: CGFloat = 8
  /// 행 왼쪽 여백 + 프로필 이미지 폭에 약간의 여유를 더한 값입니다.
  private let avatarClearance: CGFloat = 60

  let id: Note.ID
  @Binding var openSwipe: OpenNoteSwipe?
  let isPinned: Bool
  let onTogglePin: () -> Void
  let onDelete: () -> Void
  private let label: () -> Content

  @State private var dragAxis: DragAxis?
  @State private var dragTranslation: CGFloat = 0

  init(
    id: Note.ID,
    openSwipe: Binding<OpenNoteSwipe?>,
    isPinned: Bool,
    onTogglePin: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    @ViewBuilder label: @escaping () -> Content
  ) {
    self.id = id
    _openSwipe = openSwipe
    self.isPinned = isPinned
    self.onTogglePin = onTogglePin
    self.onDelete = onDelete
    self.label = label
  }

  var body: some View {
    ZStack {
      HStack {
        pinButton
          .allowsHitTesting(openEdge == .pin)
          .accessibilityHidden(openEdge != .pin)
        Spacer()
        deleteButton
          .allowsHitTesting(openEdge == .delete)
          .accessibilityHidden(openEdge != .delete)
      }

      label()
        .contentShape(Rectangle())
        // 왼쪽으로 밀 때 행 왼쪽 가장자리에 걸쳐 남는 프로필 이미지가 깔끔하게 가려지도록 덮는다.
        .overlay(alignment: .leading) {
          Color.white
            .frame(width: leadingCoverWidth)
            .allowsHitTesting(false)
        }
        .offset(x: displayedOffset)
        .simultaneousGesture(swipeGesture)
    }
    // 오른쪽으로 밀린 행이 화면 끝까지 이어지도록 오른쪽 방향으로만 클리핑 영역을 넓힌다.
    .clipShape(TrailingOverflowShape())
    .animation(noteSwipeSettleAnimation, value: openSwipe)
    .onChange(of: isPinned) { _, _ in
      close()
    }
    .accessibilityAction(named: isPinned ? "핀 해제" : "핀 추가") {
      onTogglePin()
    }
    .accessibilityAction(named: "노트 삭제") {
      onDelete()
    }
  }

  private var pinButton: some View {
    Button {
      close()
      onTogglePin()
    } label: {
      Image(.pin)
        .resizable()
        .renderingMode(.template)
        .frame(width: 20, height: 20)
        .foregroundStyle(isPinned ? .violet500 : .gray400)
        .frame(width: actionWidth, height: actionWidth)
        .background(isPinned ? .violet100 : .gray100)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .padding(.trailing, actionSpacing)
    .accessibilityLabel(isPinned ? "핀 해제" : "핀 추가")
  }

  private var deleteButton: some View {
    Button {
      close()
      onDelete()
    } label: {
      Image(.trash)
        .resizable()
        .renderingMode(.template)
        .frame(width: 20, height: 20)
        .foregroundStyle(.errorRed)
        .frame(width: actionWidth, height: actionWidth)
        .background(.errorRed.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .padding(.leading, actionSpacing)
    .accessibilityLabel("노트 삭제")
  }

  private var revealDistance: CGFloat {
    actionWidth + actionSpacing
  }

  /// 이 행이 열려 있을 때의 열린 방향입니다. 닫혀 있으면 nil입니다.
  private var openEdge: OpenNoteSwipe.Edge? {
    guard let current = openSwipe, current.id == id else {
      return nil
    }
    return current.edge
  }

  private var restingOffset: CGFloat {
    switch openEdge {
    case .pin: return revealDistance
    case .delete: return -revealDistance
    case nil: return 0
    }
  }

  private var displayedOffset: CGFloat {
    let dragged = dragAxis == .horizontal ? dragTranslation : 0
    return resistedOffset(restingOffset + dragged)
  }

  /// 액션 너비까지는 손가락을 그대로 따라가고, 그 이상은 고무줄처럼 저항을 준다.
  private func resistedOffset(_ offset: CGFloat) -> CGFloat {
    let distance = abs(offset)
    guard distance > revealDistance else {
      return offset
    }

    let direction: CGFloat = offset < 0 ? -1 : 1
    let overflow = distance - revealDistance
    return direction * (revealDistance + overflow * 0.18)
  }

  /// 밀린 거리에 비례해 키워서, 완전히 열렸을 때 프로필 이미지까지 가려지게 한다.
  private var leadingCoverWidth: CGFloat {
    let swipedLeft = max(0, -displayedOffset)
    return swipedLeft * (avatarClearance / revealDistance)
  }

  private func close() {
    guard let current = openSwipe, current.id == id else {
      return
    }
    openSwipe = nil
  }

  private var swipeGesture: some Gesture {
    DragGesture(minimumDistance: 12)
      .onChanged { value in
        // 방향은 제스처 시작 시 한 번만 정하고 이후에는 바꾸지 않는다.
        if dragAxis == nil {
          dragAxis = abs(value.translation.width) > abs(value.translation.height)
            ? .horizontal
            : .vertical

          if dragAxis == .horizontal {
            // 다른 행이 열려 있으면 먼저 닫는다.
            if let current = openSwipe, current.id != id {
              openSwipe = nil
            }
          } else {
            // 세로 스크롤을 시작하면 열린 행을 닫는다.
            openSwipe = nil
          }
        }

        if dragAxis == .horizontal {
          dragTranslation = value.translation.width
        }
      }
      .onEnded { value in
        let wasHorizontal = dragAxis == .horizontal
        let wasOpenOffset = restingOffset

        // 예측값은 일부만 반영해서 작은 플릭이 과하게 투영되지 않게 한다.
        let currentOffset = wasOpenOffset + value.translation.width
        let projectedDelta = value.predictedEndTranslation.width - value.translation.width
        let proposedOffset = currentOffset + projectedDelta * 0.2

        // 정리 전체를 애니메이션으로 묶어서 임계값 미달 시에도 부드럽게 돌아가게 한다.
        withAnimation(noteSwipeSettleAnimation) {
          dragAxis = nil
          dragTranslation = 0

          guard wasHorizontal else {
            return
          }

          if proposedOffset > revealDistance / 2 {
            // 반대쪽이 열려 있었다면 한 번에 넘기지 않고 먼저 닫는다.
            if wasOpenOffset < 0 {
              close()
            } else {
              openSwipe = OpenNoteSwipe(id: id, edge: .pin)
            }
          } else if proposedOffset < -revealDistance / 2 {
            if wasOpenOffset > 0 {
              close()
            } else {
              openSwipe = OpenNoteSwipe(id: id, edge: .delete)
            }
          } else {
            close()
          }
        }
      }
  }
}

/// 위, 아래, 왼쪽은 뷰 경계에서 자르고 오른쪽만 넓게 열어 두는 클리핑 모양입니다.
private struct TrailingOverflowShape: Shape {
  func path(in rect: CGRect) -> Path {
    Path(CGRect(x: rect.minX, y: rect.minY, width: rect.width + 400, height: rect.height))
  }
}
