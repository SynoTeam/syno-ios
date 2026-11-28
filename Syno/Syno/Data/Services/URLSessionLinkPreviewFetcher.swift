import Foundation

struct URLSessionLinkPreviewFetcher: NoteLinkPreviewFetching {
  func fetchPreview(for url: URL) async throws -> NoteLinkPreviewResult {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let response = response as? HTTPURLResponse, 200..<400 ~= response.statusCode else {
      throw URLError(.badServerResponse)
    }

    let metadata = OpenGraphMetadata(data: data, textEncodingName: response.textEncodingName)
    let title = metadata.value(for: "og:title") ?? metadata.title ?? url.host ?? url.absoluteString
    let siteURL = metadata.value(for: "og:url").flatMap(URL.init(string:)) ?? url
    let imageURL = metadata.imageURL(relativeTo: siteURL)
    return NoteLinkPreviewResult(title: title, imageURL: imageURL, siteURL: siteURL)
  }
}

/// 링크 미리보기용 HTML 메타 정보(og:title, og:image, <title>)를 읽습니다.
/// 값에 들어 있는 HTML 표기(&amp;, &#x3D; 등)는 풀어서 돌려줍니다 (#146).
struct OpenGraphMetadata {
  private let html: String

  init(html: String) {
    self.html = html
  }

  /// 서버가 알려 준 인코딩 → 페이지 안의 meta charset → UTF-8 순서로, 읽을 수 있는 첫 인코딩으로 읽습니다.
  /// 서버가 인코딩을 잘못 알려 줘서 읽지 못하면 다음 후보로 넘어갑니다.
  /// 국내 사이트 일부는 아직 EUC-KR이라 UTF-8로만 읽으면 제목이 깨집니다.
  init(data: Data, textEncodingName: String?) {
    let candidates = [textEncodingName, Self.declaredCharset(in: data)]
      .compactMap { $0.flatMap(Self.encoding(named:)) } + [.utf8]
    html = candidates.lazy.compactMap { String(data: data, encoding: $0) }.first
      ?? String(decoding: data, as: UTF8.self)
  }

  func value(for key: String) -> String? {
    guard let expression = try? NSRegularExpression(pattern: "<meta\\b[^>]*>", options: [.caseInsensitive]) else { return nil }
    let range = NSRange(html.startIndex..., in: html)
    for match in expression.matches(in: html, range: range) {
      guard let tagRange = Range(match.range, in: html) else { continue }
      let tag = String(html[tagRange])
      let property = attribute(named: "property", in: tag) ?? attribute(named: "name", in: tag)
      if property?.lowercased() == key.lowercased(), let content = attribute(named: "content", in: tag) {
        return Self.decodingEntities(content)
      }
    }
    return nil
  }

  /// og:image 주소입니다. 상대 주소는 페이지 주소 기준으로 풀고, http는 https로 바꿉니다.
  /// iOS 보안 정책(ATS)이 http 이미지를 막아, 그대로 두면 썸네일이 비어 보입니다.
  func imageURL(relativeTo pageURL: URL) -> URL? {
    guard let value = value(for: "og:image"), !value.isEmpty,
          let url = URL(string: value, relativeTo: pageURL)?.absoluteURL,
          var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else { return nil }
    if components.scheme?.lowercased() == "http" {
      components.scheme = "https"
    }
    return components.url
  }

  var title: String? {
    guard let expression = try? NSRegularExpression(pattern: "<title[^>]*>(.*?)</title>", options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
    let range = NSRange(html.startIndex..., in: html)
    guard let match = expression.firstMatch(in: html, range: range), let titleRange = Range(match.range(at: 1), in: html) else { return nil }
    return Self.decodingEntities(String(html[titleRange])).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// 값을 감싼 따옴표와 같은 따옴표까지만 읽습니다. 큰따옴표 값 안의 작은따옴표(Rick's)에서 잘리지 않게 합니다.
  private func attribute(named name: String, in tag: String) -> String? {
    let pattern = "\\b\(name)\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')"
    guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
    let range = NSRange(tag.startIndex..., in: tag)
    guard let match = expression.firstMatch(in: tag, range: range) else { return nil }
    for group in 1...2 {
      if let valueRange = Range(match.range(at: group), in: tag) {
        return String(tag[valueRange])
      }
    }
    return nil
  }

  private static let namedEntities: [String: String] = [
    "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ",
  ]

  /// &amp; 같은 이름 표기와 &#38;, &#x3D; 같은 숫자 표기를 글자로 바꿉니다. 모르는 표기는 그대로 둡니다.
  static func decodingEntities(_ text: String) -> String {
    guard text.contains("&"),
          let expression = try? NSRegularExpression(pattern: "&(#[xX][0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);")
    else { return text }
    var result = ""
    var cursor = text.startIndex
    for match in expression.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
      guard let whole = Range(match.range, in: text), let body = Range(match.range(at: 1), in: text) else { continue }
      result += text[cursor..<whole.lowerBound]
      result += replacement(for: String(text[body])) ?? String(text[whole])
      cursor = whole.upperBound
    }
    result += text[cursor...]
    return result
  }

  private static func replacement(for entity: String) -> String? {
    if entity.hasPrefix("#x") || entity.hasPrefix("#X") {
      return UInt32(entity.dropFirst(2), radix: 16).flatMap(Unicode.Scalar.init).map { String(Character($0)) }
    }
    if entity.hasPrefix("#") {
      return UInt32(entity.dropFirst()).flatMap(Unicode.Scalar.init).map { String(Character($0)) }
    }
    return namedEntities[entity.lowercased()]
  }

  private static func encoding(named name: String) -> String.Encoding? {
    let cfEncoding = CFStringConvertIANACharSetNameToEncoding(name as CFString)
    guard cfEncoding != kCFStringEncodingInvalidId else { return nil }
    return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
  }

  /// 페이지 앞부분의 <meta charset="..."> 또는 content="text/html; charset=..."에서 인코딩 이름을 찾습니다.
  private static func declaredCharset(in data: Data) -> String? {
    let head = String(decoding: data.prefix(4_096), as: UTF8.self)
    guard
      let expression = try? NSRegularExpression(pattern: "<meta[^>]+charset\\s*=\\s*[\"']?([A-Za-z0-9_\\-]+)", options: [.caseInsensitive]),
      let match = expression.firstMatch(in: head, range: NSRange(head.startIndex..., in: head)),
      let range = Range(match.range(at: 1), in: head)
    else { return nil }
    return String(head[range])
  }
}
