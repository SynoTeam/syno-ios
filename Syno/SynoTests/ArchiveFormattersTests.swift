import Testing
@testable import Syno

/// 아카이브 텍스트 목록의 이름 표시 규칙입니다 (#142).
@MainActor
struct ArchiveFormattersTests {
  @Test("이름이 14자를 넘으면 앞 14자 뒤에 …를 붙인다", arguments: [
    // 13자, 14자는 그대로
    ("가나다라마바사아자차카타파", "가나다라마바사아자차카타파"),
    ("가나다라마바사아자차카타파하", "가나다라마바사아자차카타파하"),
    // 15자는 14자 + …
    ("가나다라마바사아자차카타파하거", "가나다라마바사아자차카타파하…"),
    // 공백도 한 글자로 센다
    ("Kim Min Su Park Jun", "Kim Min Su Par…"),
    // 이모지와 결합 문자는 화면에 보이는 글자 하나로 센다
    ("👨‍👩‍👧가나다라마바사아자차카타파하", "👨‍👩‍👧가나다라마바사아자차카타파…"),
    ("", ""),
  ])
  func contactNameText(name: String, expected: String) {
    #expect(ArchiveFormatters.contactNameText(name) == expected)
  }
}
