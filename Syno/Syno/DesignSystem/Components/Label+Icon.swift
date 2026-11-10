import SwiftUI
import UIKit

extension Label where Title == Text, Icon == Image {
  /// 메뉴와 컨텍스트 메뉴 항목처럼 시스템이 아이콘 크기를 정하는 곳에서 앱 아이콘 에셋을 템플릿으로 씁니다.
  init(_ title: String, icon resource: ImageResource) {
    self.init {
      Text(title)
    } icon: {
      Image(resource)
        .renderingMode(.template)
    }
  }

  /// `role: .destructive` 메뉴 항목에 쓰는 라벨입니다.
  /// 화면에 걸린 tint가 템플릿 아이콘에 먼저 적용되어 아이콘만 회색으로 남는 문제를 막으려고,
  /// 아이콘을 errorRed 원본 이미지로 고정합니다.
  init(_ title: String, destructiveIcon resource: ImageResource) {
    self.init {
      Text(title)
    } icon: {
      Image(uiImage: UIImage(resource: resource).withTintColor(UIColor(resource: .errorRed), renderingMode: .alwaysOriginal))
    }
  }
}
