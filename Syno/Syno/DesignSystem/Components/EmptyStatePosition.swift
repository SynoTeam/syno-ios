import SwiftUI

extension View {
  /// 빈 화면의 그림과 문구를 화면 정중앙보다 조금 위에 둡니다 (#138).
  /// 가운데 정렬된 빈 화면에 붙이며, 레이아웃 크기는 바꾸지 않고 보이는 위치만 올립니다.
  func emptyStatePosition() -> some View {
    offset(y: -30)
  }
}
