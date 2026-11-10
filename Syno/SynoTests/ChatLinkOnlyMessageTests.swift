import Testing
@testable import Syno

/// 링크만 보낸 메시지는 주소 텍스트 없이 링크 미리보기 카드만 보여준다 (#116).
/// 예시표 한 줄이 테스트 한 줄입니다.
struct ChatLinkOnlyMessageTests {
  @Test(
    "내용 전체가 링크 하나면 링크만 있는 메시지다",
    arguments: [
      "https://example.com",
      "  https://example.com \n",
      "https://n.news.naver.com/mnews/article/023/0004007300?sid=101",
      "naver.com",
    ]
  )
  func linkOnly(content: String) {
    #expect(ChatMessageBubble.isLinkOnly(content))
  }

  @Test(
    "링크와 다른 글이 섞였거나 링크가 없으면 링크만 있는 메시지가 아니다",
    arguments: [
      "이거 봐 https://example.com",
      "https://example.com 여기 봐",
      "https://a.com https://b.com",
      "링크 없는 메시지",
      "",
      "   ",
    ]
  )
  func notLinkOnly(content: String) {
    #expect(!ChatMessageBubble.isLinkOnly(content))
  }
}
