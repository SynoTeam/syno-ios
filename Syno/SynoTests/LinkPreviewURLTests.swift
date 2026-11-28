import Foundation
import Testing
@testable import Syno

/// 메시지에서 미리보기를 가져올 주소를 고르는 규칙입니다 (#146).
/// iOS는 보안 정책(ATS)으로 http 요청을 막으므로, 사용자가 http://를 직접 쓰지 않은 주소는 https로 요청합니다.
struct LinkPreviewURLTests {
  @Test("주소만 붙인 링크는 https로, 사용자가 쓴 scheme은 그대로", arguments: [
    // 주소만 보낸 경우: 인식기가 http를 붙이지만 https로 요청한다
    ("naver.com", "https://naver.com"),
    ("www.naver.com", "https://www.naver.com"),
    ("m.blog.naver.com/abc?x=1", "https://m.blog.naver.com/abc?x=1"),
    ("보세요 naver.com 여기", "https://naver.com"),
    // 쿼리 안의 ://는 사용자가 쓴 scheme이 아니다
    ("example.com/?next=https://other.test", "https://example.com/?next=https://other.test"),
    ("naver.com/a?u=http://b.com", "https://naver.com/a?u=http://b.com"),
    // 사용자가 직접 쓴 scheme은 바꾸지 않는다(https를 지원하지 않는 사이트)
    ("https://naver.com", "https://naver.com"),
    ("http://example.com", "http://example.com"),
    ("HTTP://Example.com/a", "HTTP://Example.com/a"),
    ("링크 http://example.com/page 확인", "http://example.com/page"),
  ])
  func previewURL(text: String, expected: String) {
    #expect(LinkPreviewURL.previewURL(in: text)?.absoluteString == expected)
  }

  @Test("웹 주소가 아니면 미리보기를 가져오지 않는다", arguments: [
    "안녕하세요",
    "",
    "test@naver.com",
    "010-1234-5678",
  ])
  func noPreviewURL(text: String) {
    #expect(LinkPreviewURL.previewURL(in: text) == nil)
  }
}
