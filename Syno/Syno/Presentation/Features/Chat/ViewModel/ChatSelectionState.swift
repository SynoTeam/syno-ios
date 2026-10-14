import Foundation

/// 채팅에서 여러 메시지를 골라 삭제하는 선택 모드의 상태입니다.
struct ChatSelectionState: Equatable {
  /// 선택 모드가 켜져 있는지 여부입니다.
  private(set) var isActive = false
  private(set) var selectedIDs: Set<Note.ID> = []

  var count: Int {
    selectedIDs.count
  }

  var isEmpty: Bool {
    selectedIDs.isEmpty
  }

  /// 주어진 메시지를 선택한 상태로 선택 모드를 시작합니다.
  mutating func begin(with ids: [Note.ID]) {
    selectedIDs = Set(ids)
    isActive = true
  }

  /// 선택 모드를 끝내고 선택된 항목도 모두 비웁니다.
  mutating func end() {
    isActive = false
    selectedIDs = []
  }

  /// 선택 모드는 유지한 채 선택된 항목만 모두 비웁니다.
  mutating func clearSelection() {
    selectedIDs = []
  }

  /// 전부 선택되어 있으면 모두 해제하고, 아니면 모두 선택합니다.
  mutating func toggle(_ ids: [Note.ID]) {
    guard !ids.isEmpty else {
      return
    }
    if isSelected(ids) {
      selectedIDs.subtract(ids)
    } else {
      selectedIDs.formUnion(ids)
    }
  }

  /// 목록에 남아 있는 메시지만 선택 상태로 유지합니다. 선택이 모두 사라져도 선택 모드는 끝내지 않습니다.
  mutating func retain(only existingIDs: Set<Note.ID>) {
    selectedIDs.formIntersection(existingIDs)
  }

  /// 주어진 메시지가 모두 선택되어 있는지 여부입니다. 빈 목록은 선택된 것으로 보지 않습니다.
  func isSelected(_ ids: [Note.ID]) -> Bool {
    !ids.isEmpty && ids.allSatisfy { selectedIDs.contains($0) }
  }
}
