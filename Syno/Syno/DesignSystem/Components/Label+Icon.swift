import SwiftUI

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
}
