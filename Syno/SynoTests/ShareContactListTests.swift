import Foundation
import Testing
@testable import Syno

/// 공유 화면의 그룹 칩과 연락처 목록 규칙입니다 (#128).
struct ShareContactListTests {
  private static let base = Date(timeIntervalSince1970: 1_000_000)

  private let minsu = ShareContactCandidate(id: UUID(), name: "민수", group: "회사", isMe: false, profileImageData: nil)
  private let jiwoo = ShareContactCandidate(id: UUID(), name: "지우", group: "Study", isMe: false, profileImageData: nil)
  private let gana = ShareContactCandidate(id: UUID(), name: "가나", group: "", isMe: false, profileImageData: nil)
  private let me = ShareContactCandidate(id: UUID(), name: "나", group: "", isMe: true, profileImageData: nil)

  // MARK: - 그룹 칩

  @Test("그룹 칩은 사용자가 정한 순서대로, 대소문자만 다른 중복과 빈 이름은 하나로 보여준다")
  func groupNamesFollowSortOrderAndDropDuplicates() {
    let names = ShareContactList.groupNames([
      (name: "회사", sortIndex: 1),
      (name: "Study", sortIndex: 0),
      (name: "study", sortIndex: 2),
      (name: "  ", sortIndex: 3),
    ])

    #expect(names == ["Study", "회사"])
  }

  // MARK: - 최근 노트

  @Test("연락처마다 가장 최근 노트 하나만 남기고, 연락처 없는 노트는 버린다")
  func latestNotesKeepsNewestPerContact() {
    let latest = ShareContactList.latestNotes([
      (contactId: minsu.id, content: "예전", createdAt: Self.base),
      (contactId: minsu.id, content: "최근", createdAt: Self.base.addingTimeInterval(60)),
      (contactId: nil, content: "주인 없음", createdAt: Self.base.addingTimeInterval(120)),
    ])

    #expect(latest == [minsu.id: ShareLatestNote(content: "최근", createdAt: Self.base.addingTimeInterval(60))])
  }

  // MARK: - 목록

  @Test("내 프로필 연락처는 목록에 보이지 않는다")
  func rowsExcludeMe() {
    let rows = ShareContactList.rows(from: [me, minsu], latestNotes: [:], group: nil, searchText: "")

    #expect(rows.map(\.id) == [minsu.id])
  }

  @Test("최근 노트가 있는 연락처가 최근 순으로 먼저, 노트가 없는 연락처는 이름순으로 뒤에 온다")
  func rowsSortByRecentConversationThenName() {
    let notes = [
      minsu.id: ShareLatestNote(content: "a", createdAt: Self.base),
      jiwoo.id: ShareLatestNote(content: "b", createdAt: Self.base.addingTimeInterval(60)),
    ]
    let noNote = ShareContactCandidate(id: UUID(), name: "다라", group: "", isMe: false, profileImageData: nil)

    let rows = ShareContactList.rows(from: [noNote, minsu, gana, jiwoo], latestNotes: notes, group: nil, searchText: "")

    #expect(rows.map(\.name) == ["지우", "민수", "가나", "다라"])
  }

  @Test("두 번째 줄은 최근 노트 내용, 없으면 그룹명, 둘 다 없으면 비운다", arguments: [
    ("오후 2시 강남 카페 미팅", "회사", "오후 2시 강남 카페 미팅"),
    ("첫 줄\n둘째 줄", "회사", "첫 줄 둘째 줄"),
    ("  \n ", "회사", "회사"),
    (nil, "회사", "회사"),
    (nil, "", ""),
  ] as [(String?, String, String)])
  func rowSubtitle(noteContent: String?, group: String, expected: String) {
    let contact = ShareContactCandidate(id: UUID(), name: "민수", group: group, isMe: false, profileImageData: nil)
    let notes = noteContent.map { [contact.id: ShareLatestNote(content: $0, createdAt: Self.base)] } ?? [:]

    let rows = ShareContactList.rows(from: [contact], latestNotes: notes, group: nil, searchText: "")

    #expect(rows.first?.subtitle == expected)
  }

  @Test("그룹 칩을 고르면 그 그룹(대소문자 무시)의 연락처만, 전체(nil)면 모두 보여준다", arguments: [
    (nil, ["가나", "민수", "지우"]),
    ("회사", ["민수"]),
    ("study", ["지우"]),
    ("가족", []),
  ] as [(String?, [String])])
  func rowsFilterByGroup(group: String?, expected: [String]) {
    let rows = ShareContactList.rows(from: [minsu, jiwoo, gana], latestNotes: [:], group: group, searchText: "")

    #expect(rows.map(\.name) == expected)
  }

  @Test("연락처 그룹에 앞뒤 공백이 있어도 같은 그룹 칩에서 보인다")
  func groupFilterIgnoresSurroundingWhitespace() {
    let padded = ShareContactCandidate(id: UUID(), name: "공백", group: " 회사 ", isMe: false, profileImageData: nil)

    let rows = ShareContactList.rows(from: [padded], latestNotes: [:], group: "회사", searchText: "")

    #expect(rows.map(\.id) == [padded.id])
  }

  @Test("고른 연락처가 그룹 칩이나 검색으로 숨겨지면 선택되지 않은 것으로 보고, 다시 보이면 선택이 살아난다")
  func selectionCountsOnlyWhenVisible() {
    let visible = ShareContactList.rows(from: [minsu, jiwoo], latestNotes: [:], group: nil, searchText: "")
    let hidden = ShareContactList.rows(from: [minsu, jiwoo], latestNotes: [:], group: "회사", searchText: "")

    #expect(ShareContactList.visibleSelection(jiwoo.id, in: visible) == jiwoo.id)
    #expect(ShareContactList.visibleSelection(jiwoo.id, in: hidden) == nil)
    #expect(ShareContactList.visibleSelection(nil, in: visible) == nil)
  }

  @Test("검색어를 입력하면 고른 그룹 안에서 이름으로 거른다", arguments: [
    (nil, "민", ["민수"]),
    (nil, "  ", ["가나", "민수", "지우"]),
    ("회사", "지", []),
  ] as [(String?, String, [String])])
  func rowsFilterBySearchText(group: String?, searchText: String, expected: [String]) {
    let rows = ShareContactList.rows(from: [minsu, jiwoo, gana], latestNotes: [:], group: group, searchText: searchText)

    #expect(rows.map(\.name) == expected)
  }
}
