import Foundation

/// 연락처 정보(이메일, 전화번호, 웹 주소)를 외부 앱이나 페이지로 여는 URL로 변환합니다.
enum ContactLinkURL {
  /// 이메일 앱으로 이동하는 `mailto:` URL입니다. 값이 없으면 nil입니다.
  static func email(_ value: String) -> URL? {
    let email = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !email.isEmpty else {
      return nil
    }

    var components = URLComponents()
    components.scheme = "mailto"
    components.path = email
    return components.url
  }

  /// 전화 앱으로 이동하는 `tel:` URL입니다. 숫자와 국가번호의 `+`만 남깁니다.
  static func phone(_ value: String) -> URL? {
    let number = value.filter { $0.isNumber || $0 == "+" }
    guard !number.isEmpty else {
      return nil
    }
    return URL(string: "tel:\(number)")
  }

  /// 웹 페이지 URL입니다. 스킴이 없으면 https를 붙이고, http/https만 허용합니다.
  static func website(_ value: String) -> URL? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return nil
    }

    let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
    guard
      let url = URL(string: candidate),
      let scheme = url.scheme?.lowercased(),
      ["http", "https"].contains(scheme),
      url.host != nil
    else {
      return nil
    }
    return url
  }
}
