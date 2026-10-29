import SwiftUI
import UIKit

/// 왼쪽으로 미는 가로 드래그에서만 시작하는 제스처입니다.
/// SwiftUI `DragGesture`는 방향과 상관없이 가로 드래그를 잡아가서, 오른쪽으로 미는 뒤로가기 스와이프를
/// 막을 수 있습니다. 이 제스처는 오른쪽이나 세로 움직임에서는 시작하지 않아 서로 겹치지 않습니다.
struct LeftwardPanGesture: UIGestureRecognizerRepresentable {
  /// 왼쪽으로 민 거리(0 이상)를 전달합니다.
  let onChanged: (CGFloat) -> Void
  let onEnded: () -> Void

  func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
    Coordinator()
  }

  func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
    let recognizer = UIPanGestureRecognizer()
    recognizer.delegate = context.coordinator
    recognizer.cancelsTouchesInView = false
    return recognizer
  }

  func handleUIGestureRecognizerAction(
    _ recognizer: UIPanGestureRecognizer,
    context: Context
  ) {
    switch recognizer.state {
    case .began, .changed:
      onChanged(max(0, -recognizer.translation(in: recognizer.view).x))
    case .ended, .cancelled, .failed:
      onEnded()
    default:
      break
    }
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      guard
        let pan = gestureRecognizer as? UIPanGestureRecognizer,
        let view = gestureRecognizer.view
      else {
        return false
      }

      // 왼쪽 방향이면서 세로보다 확실히 가로일 때만 시작한다.
      let velocity = pan.velocity(in: view)
      return velocity.x < 0 && abs(velocity.x) > abs(velocity.y) * 1.3
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      true
    }
  }
}
