import SwiftUI

extension View {
  /// 프로필/정보 카드에 쓰는 흰색 배경 + 둥근 모서리 표면입니다.
  func surfaceCard() -> some View {
    self
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(20)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}
