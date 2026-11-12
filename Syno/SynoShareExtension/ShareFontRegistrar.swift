//
//  ShareFontRegistrar.swift
//  SynoShareExtension
//

import CoreText
import Foundation

/// 앱 번들에 들어 있는 Pretendard 글꼴을 공유 확장에서도 쓸 수 있게 등록합니다.
/// 확장 번들은 앱 번들의 `PlugIns` 폴더 안에 있으므로, 글꼴 파일을 확장에 복사하지 않고 앱 번들에서 읽습니다.
/// 등록에 실패하면 시스템 글꼴로 보입니다.
enum ShareFontRegistrar {
  private static let fontNames = ["Pretendard-Regular", "Pretendard-Medium", "Pretendard-SemiBold"]
  private static var didRegister = false

  static func registerAppFonts() {
    guard !didRegister else { return }
    didRegister = true

    // Syno.app/PlugIns/SynoShareExtension.appex → Syno.app
    let appBundleURL = Bundle.main.bundleURL
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    guard let appBundle = Bundle(url: appBundleURL) else { return }

    for name in fontNames {
      guard let url = appBundle.url(forResource: name, withExtension: "otf") else { continue }
      CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
  }
}
