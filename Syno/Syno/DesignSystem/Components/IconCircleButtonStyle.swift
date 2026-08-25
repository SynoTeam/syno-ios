import SwiftUI

/// Figma `IconButton/Circular` 컴포넌트에 대응하는 원형 아이콘 버튼 스타일입니다.
/// 색상 역할은 `btn_CTA`와 동일한 ``SynoButtonRole``을 공유합니다.
enum IconCircleSize: CGFloat {
  case small = 32
  case medium = 44
  case large = 54
}

struct IconCircleButtonStyle: ButtonStyle {
  var role: SynoButtonRole = .tertiary
  var size: IconCircleSize = .medium

  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    let colors = role.colors(isPressed: configuration.isPressed)

    configuration.label
      .foregroundStyle(colors.foreground)
      .frame(width: size.rawValue, height: size.rawValue)
      .background(colors.background)
      .clipShape(Circle())
      .opacity(isEnabled ? 1 : 0.4)
  }
}

extension ButtonStyle where Self == IconCircleButtonStyle {
  static func iconCircle(_ role: SynoButtonRole = .tertiary, size: IconCircleSize = .medium) -> IconCircleButtonStyle {
    IconCircleButtonStyle(role: role, size: size)
  }
}
