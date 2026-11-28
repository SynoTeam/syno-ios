import Foundation
import Testing
@testable import Syno

/// 링크 미리보기용 HTML 메타 정보 해석 규칙입니다 (#146).
struct OpenGraphMetadataTests {
  @Test("메타 태그 값의 HTML 표기를 풀어서 읽는다", arguments: [
    // 네이버 뉴스: = 이 &#x3D; 로 들어 있다
    (#"<meta property="og:image" content="https://img.pstatic.net/a.jpg?type&#x3D;w800">"#, "https://img.pstatic.net/a.jpg?type=w800"),
    (#"<meta property="og:image" content="https://a.com/i.jpg?w=1&amp;h=2">"#, "https://a.com/i.jpg?w=1&h=2"),
    (#"<meta property="og:image" content="https://a.com/i.jpg?w=1&#38;h=2">"#, "https://a.com/i.jpg?w=1&h=2"),
    // content가 property보다 앞에 있어도 읽는다
    (#"<meta content="https://a.com/i.jpg" property="og:image" />"#, "https://a.com/i.jpg"),
  ])
  func imageValue(html: String, expected: String) {
    #expect(OpenGraphMetadata(html: html).value(for: "og:image") == expected)
  }

  @Test("썸네일 주소는 페이지 주소 기준으로 풀고, http는 https로 요청한다(iOS가 http 이미지를 막음)", arguments: [
    (#"<meta property="og:image" content="http://img.a.com/i.jpg">"#, "https://a.com/post", "https://img.a.com/i.jpg"),
    (#"<meta property="og:image" content="/images/i.jpg">"#, "https://a.com/post", "https://a.com/images/i.jpg"),
    (#"<meta property="og:image" content="//cdn.a.com/i.jpg">"#, "https://a.com/post", "https://cdn.a.com/i.jpg"),
    (#"<meta property="og:image" content="https://cdn.a.com/i.jpg">"#, "http://m.a.com/", "https://cdn.a.com/i.jpg"),
  ])
  func imageURL(html: String, pageURL: String, expected: String) {
    #expect(OpenGraphMetadata(html: html).imageURL(relativeTo: URL(string: pageURL)!)?.absoluteString == expected)
  }

  @Test("썸네일이 없으면 nil")
  func noImage() {
    #expect(OpenGraphMetadata(html: "<title>a</title>").imageURL(relativeTo: URL(string: "https://a.com")!) == nil)
  }

  @Test("제목의 HTML 표기와 따옴표를 그대로 살린다", arguments: [
    (#"<meta property="og:title" content="&quot;AI&quot; 시대 &amp; 메모">"#, #""AI" 시대 & 메모"#),
    // 큰따옴표로 감싼 값 안의 작은따옴표에서 잘리지 않는다
    (#"<meta property="og:title" content="Rick's Video">"#, "Rick's Video"),
    (#"<meta property='og:title' content='Say "Hi"'>"#, #"Say "Hi""#),
    (#"<meta property="og:title" content="&#54620;&#44544;">"#, "한글"),
  ])
  func titleValue(html: String, expected: String) {
    #expect(OpenGraphMetadata(html: html).value(for: "og:title") == expected)
  }

  @Test("<title> 태그의 HTML 표기도 푼다")
  func titleTag() {
    #expect(OpenGraphMetadata(html: "<title> A &amp; B </title>").title == "A & B")
  }

  @Test("UTF-8이 아닌 페이지(EUC-KR)도 글자가 깨지지 않는다")
  func eucKRPage() throws {
    let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.EUC_KR.rawValue)))
    let html = #"<html><head><meta charset="euc-kr"><title>네이버 카페</title></head></html>"#
    let data = try #require(html.data(using: encoding))

    // 서버가 인코딩을 알려 준 경우와, 페이지 안 meta charset으로만 알 수 있는 경우
    #expect(OpenGraphMetadata(data: data, textEncodingName: "euc-kr").title == "네이버 카페")
    #expect(OpenGraphMetadata(data: data, textEncodingName: nil).title == "네이버 카페")
  }

  @Test("서버가 알려 준 인코딩으로 읽지 못하면 페이지의 meta charset으로 다시 읽는다")
  func wrongHeaderEncoding() throws {
    let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.EUC_KR.rawValue)))
    let html = #"<html><head><meta charset="euc-kr"><title>네이버 카페</title></head></html>"#
    let data = try #require(html.data(using: encoding))

    // 본문은 EUC-KR인데 서버가 utf-8이라고 알려 준 경우
    #expect(OpenGraphMetadata(data: data, textEncodingName: "utf-8").title == "네이버 카페")
  }

  @Test("인코딩 정보가 없으면 UTF-8로 읽는다")
  func utf8Default() throws {
    let data = try #require("<title>한글 제목</title>".data(using: .utf8))
    #expect(OpenGraphMetadata(data: data, textEncodingName: nil).title == "한글 제목")
  }
}
