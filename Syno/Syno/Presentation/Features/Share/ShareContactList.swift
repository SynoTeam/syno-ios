import Foundation

/// 공유 화면 목록을 만들 때 쓰는 연락처 정보입니다.
nonisolated struct ShareContactCandidate: Equatable {
  let id: UUID
  let name: String
  let group: String
  let isMe: Bool
  let profileImageData: Data?
}

/// 연락처별 가장 최근 노트입니다. 사진·음성·파일 데이터는 담지 않습니다.
nonisolated struct ShareLatestNote: Equatable {
  let content: String
  let createdAt: Date
}

/// 공유 화면의 연락처 행 하나입니다.
nonisolated struct ShareContactRow: Identifiable, Equatable {
  let id: UUID
  let name: String
  let subtitle: String
  let profileImageData: Data?
}

/// 공유 화면의 그룹 칩과 연락처 목록 규칙입니다 (#128).
/// 공유 확장 타깃과 앱 타깃이 함께 컴파일합니다. 앱 타깃에 있는 이유는 단위 테스트 때문입니다.
nonisolated enum ShareContactList {
  /// 사용자가 정한 순서대로 그룹 이름을 돌려줍니다. 대소문자만 다른 중복과 빈 이름은 뺍니다.
  static func groupNames(_ groups: [(name: String, sortIndex: Int)]) -> [String] {
    var seen: Set<String> = []
    return groups
      .sorted { $0.sortIndex < $1.sortIndex }
      .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
  }

  /// 연락처마다 가장 최근 노트 하나를 고릅니다. 연락처가 없는 노트는 버립니다.
  static func latestNotes(
    _ notes: [(contactId: UUID?, content: String, createdAt: Date)]
  ) -> [UUID: ShareLatestNote] {
    var latest: [UUID: ShareLatestNote] = [:]
    for note in notes {
      guard let contactId = note.contactId else { continue }
      if let current = latest[contactId], current.createdAt >= note.createdAt { continue }
      latest[contactId] = ShareLatestNote(content: note.content, createdAt: note.createdAt)
    }
    return latest
  }

  /// 내 프로필을 빼고, 그룹과 검색어로 거른 뒤 최근 대화순(노트 없으면 이름순)으로 정렬합니다.
  /// `group`이 nil이면 전체입니다.
  static func rows(
    from candidates: [ShareContactCandidate],
    latestNotes: [UUID: ShareLatestNote],
    group: String?,
    searchText: String
  ) -> [ShareContactRow] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    return candidates
      .filter { !$0.isMe }
      .filter { contact in
        guard let group else { return true }
        return contact.group.compare(group, options: .caseInsensitive) == .orderedSame
      }
      .filter { query.isEmpty || $0.name.localizedStandardContains(query) }
      .sorted { lhs, rhs in
        switch (latestNotes[lhs.id]?.createdAt, latestNotes[rhs.id]?.createdAt) {
        case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
          return lhsDate > rhsDate
        case (.some, nil):
          return true
        case (nil, .some):
          return false
        default:
          return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
      }
      .map { contact in
        ShareContactRow(
          id: contact.id,
          name: contact.name,
          subtitle: subtitle(note: latestNotes[contact.id], group: contact.group),
          profileImageData: contact.profileImageData
        )
      }
  }

  /// 고른 연락처가 지금 목록에 보일 때만 선택된 것으로 봅니다.
  /// 그룹 칩이나 검색으로 숨겨진 연락처에 저장하지 않게 하기 위해서입니다.
  static func visibleSelection(_ selectedID: UUID?, in rows: [ShareContactRow]) -> UUID? {
    guard let selectedID, rows.contains(where: { $0.id == selectedID }) else { return nil }
    return selectedID
  }

  /// 최근 노트 내용을 한 줄로, 없으면 그룹명을 보여줍니다.
  private static func subtitle(note: ShareLatestNote?, group: String) -> String {
    let content = (note?.content ?? "")
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
    return content.isEmpty ? group : content
  }
}
