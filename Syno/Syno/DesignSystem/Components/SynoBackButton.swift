import SwiftUI
import UIKit

/// 시스템 뒤로가기 버튼 대신 앱 아이콘 에셋(24×24)의 뒤로가기 버튼을 보여줍니다.
private struct SynoBackButtonModifier: ViewModifier {
  @Environment(\.dismiss) private var dismiss
  let isHidden: Bool

  func body(content: Content) -> some View {
    content
      .navigationBarBackButtonHidden(true)
      .toolbar {
        if !isHidden {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              dismiss()
            } label: {
              Image(.chevronLeft)
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                // `<`는 꼭짓점이 왼쪽이라 정중앙에 두면 오른쪽으로 쏠려 보여, 시스템 뒤로가기처럼 살짝 왼쪽으로 보정한다.
                .offset(x: -1)
            }
            .accessibilityLabel("뒤로")
          }
        }
      }
  }
}

extension View {
  /// 시스템 뒤로가기 버튼을 숨기고 앱 아이콘의 뒤로가기 버튼을 붙입니다.
  /// 선택 모드처럼 뒤로가기를 막아야 할 때는 `isHidden`을 `true`로 둡니다.
  func synoBackButton(isHidden: Bool = false) -> some View {
    modifier(SynoBackButtonModifier(isHidden: isHidden))
  }
}

/// 시스템 뒤로가기 버튼을 숨겨도 화면 가장자리에서 밀어 뒤로 가는 제스처가 계속 동작하게 합니다.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
  override open func viewDidLoad() {
    super.viewDidLoad()
    interactivePopGestureRecognizer?.delegate = self
  }

  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    viewControllers.count > 1
  }
}
