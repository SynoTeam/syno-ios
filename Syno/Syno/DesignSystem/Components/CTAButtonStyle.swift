import SwiftUI

/// Figma `btn_CTA` 컴포넌트에 대응하는 캡슐형 CTA 버튼 스타일입니다.
/// `Button`/`NavigationLink` label에 `.buttonStyle(.cta(role))`로 적용합니다.
/// Disabled 상태는 역할과 무관하게 Default 색상에 opacity 40%를 적용합니다.
enum SynoButtonRole {
  case primary
  case secondary
  case tertiary
  case destructive

  func colors(isPressed: Bool) -> (background: Color, foreground: Color) {
    switch self {
    case .primary:
      (isPressed ? .violet800 : .violet600, .white)
    case .secondary:
      (isPressed ? .violet200 : .violet100, isPressed ? .violet800 : .violet600)
    case .tertiary:
      (isPressed ? .gray200 : .gray100, .gray600)
    case .destructive:
      (isPressed ? .bgRed02 : .bgRed01, .errorRed)
    }
  }
}

struct CTAButtonStyle: ButtonStyle {
  var role: SynoButtonRole = .primary

  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    let colors = role.colors(isPressed: configuration.isPressed)

    configuration.label
      .typeStyle(.headline)
      .foregroundStyle(colors.foreground)
      .frame(maxWidth: .infinity, minHeight: 60)
      .background(colors.background)
      .clipShape(Capsule())
      .contentShape(Capsule())
      .opacity(isEnabled ? 1 : 0.4)
  }
}

extension ButtonStyle where Self == CTAButtonStyle {
  static func cta(_ role: SynoButtonRole = .primary) -> CTAButtonStyle {
    CTAButtonStyle(role: role)
  }
}
