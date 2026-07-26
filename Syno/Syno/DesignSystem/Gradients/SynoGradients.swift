import SwiftUI

extension LinearGradient {
  /// #633EFF → #D084FF
  static let gradient01 = LinearGradient(
    colors: [
      Color(red: 0x63 / 255, green: 0x3E / 255, blue: 0xFF / 255),
      Color(red: 0xD0 / 255, green: 0x84 / 255, blue: 0xFF / 255)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  /// #8BA0FF → #D084FF
  static let gradient02 = LinearGradient(
    colors: [
      Color(red: 0x8B / 255, green: 0xA0 / 255, blue: 0xFF / 255),
      Color(red: 0xD0 / 255, green: 0x84 / 255, blue: 0xFF / 255)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
}
