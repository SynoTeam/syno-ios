//
//  NoteFilter.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

/// 노트 목록 상단에서 선택하는 필터입니다.
enum NoteFilter: Hashable, CaseIterable {
  case all
  case favorite

  var title: String {
    switch self {
    case .all:
      "All"
    case .favorite:
      "Favorite"
    }
  }
}
