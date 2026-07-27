import SwiftUI

extension LinearGradient {
  static let gradient01 = LinearGradient(
    colors: [
      Color.gradient01,
      Color.gradient03
    ],
    startPoint: .leading,
    endPoint: .trailing
  )

  static let gradient02 = LinearGradient(
    colors: [
      Color.gradient02,
      Color.gradient03
    ],
    startPoint: .leading,
    endPoint: .trailing
  )
}
