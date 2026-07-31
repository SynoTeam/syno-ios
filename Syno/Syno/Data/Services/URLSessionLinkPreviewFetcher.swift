import Foundation

struct URLSessionLinkPreviewFetcher: NoteLinkPreviewFetching {
  func fetchPreview(for url: URL) async throws -> NoteLinkPreviewResult {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let response = response as? HTTPURLResponse, 200..<400 ~= response.statusCode else {
      throw URLError(.badServerResponse)
    }

    let html = String(decoding: data, as: UTF8.self)
    let metadata = OpenGraphMetadata(html: html)
    let title = metadata.value(for: "og:title") ?? metadata.title ?? url.host ?? url.absoluteString
    let siteURL = metadata.value(for: "og:url").flatMap(URL.init(string:)) ?? url
    let imageURL = metadata.value(for: "og:image").flatMap { URL(string: $0, relativeTo: siteURL)?.absoluteURL }
    return NoteLinkPreviewResult(title: title, imageURL: imageURL, siteURL: siteURL)
  }
}

private struct OpenGraphMetadata {
  private let html: String

  init(html: String) {
    self.html = html
  }

  func value(for key: String) -> String? {
    guard let expression = try? NSRegularExpression(pattern: "<meta\\b[^>]*>", options: [.caseInsensitive]) else { return nil }
    let range = NSRange(html.startIndex..., in: html)
    for match in expression.matches(in: html, range: range) {
      guard let tagRange = Range(match.range, in: html) else { continue }
      let tag = String(html[tagRange])
      let property = attribute(named: "property", in: tag) ?? attribute(named: "name", in: tag)
      if property?.lowercased() == key.lowercased(), let content = attribute(named: "content", in: tag) {
        return content
      }
    }
    return nil
  }

  var title: String? {
    guard let expression = try? NSRegularExpression(pattern: "<title[^>]*>(.*?)</title>", options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
    let range = NSRange(html.startIndex..., in: html)
    guard let match = expression.firstMatch(in: html, range: range), let titleRange = Range(match.range(at: 1), in: html) else { return nil }
    return String(html[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func attribute(named name: String, in tag: String) -> String? {
    let pattern = "\\b\(name)\\s*=\\s*[\\\"']([^\\\"']*)[\\\"']"
    guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
    let range = NSRange(tag.startIndex..., in: tag)
    guard let match = expression.firstMatch(in: tag, range: range), let valueRange = Range(match.range(at: 1), in: tag) else { return nil }
    return String(tag[valueRange])
  }
}
