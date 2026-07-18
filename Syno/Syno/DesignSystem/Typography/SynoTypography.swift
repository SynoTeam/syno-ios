import SwiftUI
import UIKit

struct TypeStyle {
  let font: Font
  let uiFont: UIFont
  let size: CGFloat
  let lineHeight: CGFloat
  let letterSpacing: CGFloat

  var extraSpacing: CGFloat {
    max((size * lineHeight) - uiFont.lineHeight, 0)
  }

  var letterSpacingPoints: CGFloat {
    letterSpacing * size
  }
}

extension Font {
  enum Pretendard: String {
    case bold = "Pretendard-Bold"
    case semibold = "Pretendard-SemiBold"
    case medium = "Pretendard-Medium"
    case regular = "Pretendard-Regular"

    func uiFont(size: CGFloat) -> UIFont {
      UIFont(name: rawValue, size: size) ?? .systemFont(ofSize: size)
    }

    func swiftUIFont(size: CGFloat) -> Font {
      .custom(rawValue, fixedSize: size)
    }
  }
}

extension TypeStyle {
  static let header = TypeStyle(
    font: Font.Pretendard.semibold.swiftUIFont(size: 24),
    uiFont: Font.Pretendard.semibold.uiFont(size: 24),
    size: 24,
    lineHeight: 26 / 24,
    letterSpacing: 0
  )

  static let largeTitle = TypeStyle(
    font: Font.Pretendard.regular.swiftUIFont(size: 34),
    uiFont: Font.Pretendard.regular.uiFont(size: 34),
    size: 34,
    lineHeight: 41 / 34,
    letterSpacing: 0.4 / 34
  )

  static let title1 = TypeStyle(
    font: Font.Pretendard.regular.swiftUIFont(size: 28),
    uiFont: Font.Pretendard.regular.uiFont(size: 28),
    size: 28,
    lineHeight: 34 / 28,
    letterSpacing: 0.38 / 28
  )

  static let title2 = TypeStyle(
    font: Font.Pretendard.regular.swiftUIFont(size: 22),
    uiFont: Font.Pretendard.regular.uiFont(size: 22),
    size: 22,
    lineHeight: 28 / 22,
    letterSpacing: -0.26 / 22
  )

  static let title3 = TypeStyle(
    font: Font.Pretendard.regular.swiftUIFont(size: 20),
    uiFont: Font.Pretendard.regular.uiFont(size: 20),
    size: 20,
    lineHeight: 25 / 20,
    letterSpacing: -0.45 / 20
  )

  static let headline = TypeStyle(
    font: Font.Pretendard.semibold.swiftUIFont(size: 17),
    uiFont: Font.Pretendard.semibold.uiFont(size: 17),
    size: 17,
    lineHeight: 22 / 17,
    letterSpacing: -0.43 / 17
  )

  static let body = TypeStyle(
    font: Font.Pretendard.regular.swiftUIFont(size: 17),
    uiFont: Font.Pretendard.regular.uiFont(size: 17),
    size: 17,
    lineHeight: 22 / 17,
    letterSpacing: -0.43 / 17
  )

  static let callout = TypeStyle(
    font: Font.Pretendard.medium.swiftUIFont(size: 16),
    uiFont: Font.Pretendard.medium.uiFont(size: 16),
    size: 16,
    lineHeight: 21 / 16,
    letterSpacing: -0.31 / 16
  )

  static let subheadline = TypeStyle(
    font: Font.Pretendard.medium.swiftUIFont(size: 15),
    uiFont: Font.Pretendard.medium.uiFont(size: 15),
    size: 15,
    lineHeight: 20 / 15,
    letterSpacing: -0.23 / 15
  )

  static let footnote = TypeStyle(
    font: Font.Pretendard.regular.swiftUIFont(size: 13),
    uiFont: Font.Pretendard.regular.uiFont(size: 13),
    size: 13,
    lineHeight: 18 / 13,
    letterSpacing: -0.2 / 13
  )

  static let caption1 = TypeStyle(
    font: Font.Pretendard.medium.swiftUIFont(size: 12),
    uiFont: Font.Pretendard.medium.uiFont(size: 12),
    size: 12,
    lineHeight: 16 / 12,
    letterSpacing: 0
  )

  static let caption2 = TypeStyle(
    font: Font.Pretendard.medium.swiftUIFont(size: 11),
    uiFont: Font.Pretendard.medium.uiFont(size: 11),
    size: 11,
    lineHeight: 13 / 10,
    letterSpacing: 0.06 / 10
  )
}

extension View {
  func typeStyle(_ style: TypeStyle) -> some View {
    self
      .tracking(style.letterSpacingPoints)
      .font(style.font)
      .lineSpacing(style.extraSpacing)
  }
}
