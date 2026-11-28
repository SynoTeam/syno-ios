import Foundation

/// 메시지에서 링크 미리보기를 가져올 주소를 고르는 규칙입니다 (#146).
enum LinkPreviewURL {
  /// 메시지의 첫 웹 주소입니다. 웹 주소(http, https)가 아니면 nil입니다.
  ///
  /// "naver.com"처럼 scheme 없이 쓴 주소는 주소 인식기가 http://를 붙이는데, iOS 보안 정책(ATS)이
  /// http 요청을 막아 미리보기를 가져오지 못합니다. 사용자가 http://를 직접 쓰지 않았다면 https로 요청합니다.
  /// 사용자가 직접 쓴 scheme은 https를 지원하지 않는 사이트일 수 있어 바꾸지 않습니다.
  static func previewURL(in text: String) -> URL? {
    guard
      let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
      let match = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
      let url = match.url,
      let scheme = url.scheme?.lowercased(),
      scheme == "http" || scheme == "https"
    else {
      return nil
    }

    let matchedText = (text as NSString).substring(with: match.range)
    // 주소가 scheme으로 시작하는지만 본다. 쿼리 안의 ://(예: ?next=https://...)는 사용자가 쓴 scheme이 아니다.
    let hasWrittenScheme = matchedText.lowercased().hasPrefix("\(scheme)://")
    guard !hasWrittenScheme, scheme == "http" else { return url }

    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    components?.scheme = "https"
    return components?.url ?? url
  }
}
