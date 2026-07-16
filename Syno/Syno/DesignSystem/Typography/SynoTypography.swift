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
  static let screenTitle = TypeStyle(
    font: Font.Pretendard.semibold.swiftUIFont(size: 24),
    uiFont: Font.Pretendard.semibold.uiFont(size: 24),
    size: 34,
    lineHeight: 1.2,
    letterSpacing: 0
  )
  
  static let sectionTitle = TypeStyle(
    font: Font.Pretendard.semibold.swiftUIFont(size: 16),
    uiFont: Font.Pretendard.semibold.uiFont(size: 16),
    size: 24,
    lineHeight: 1.3,
    letterSpacing: 0
  )
  
  static let countBadge = TypeStyle(
    font: Font.Pretendard.medium.swiftUIFont(size: 14),
    uiFont: Font.Pretendard.medium.uiFont(size: 14),
    size: 16,
    lineHeight: 1.2,
    letterSpacing: 0
  )
  
  static let contactName = TypeStyle(
    font: Font.Pretendard.medium.swiftUIFont(size: 16),
    uiFont: Font.Pretendard.medium.uiFont(size: 16),
    size: 16,
    lineHeight: 1.3,
    letterSpacing: 0
  )
  
  static let contactMeta = TypeStyle(
    font: Font.Pretendard.regular.swiftUIFont(size: 13),
    uiFont: Font.Pretendard.regular.uiFont(size: 13),
    size: 13,
    lineHeight: 1.3,
    letterSpacing: 0
  )
}

extension Text {
  func typeStyle(_ style: TypeStyle) -> some View {
    self
      .tracking(style.letterSpacingPoints)
      .font(style.font)
      .lineSpacing(style.extraSpacing)
  }
}
