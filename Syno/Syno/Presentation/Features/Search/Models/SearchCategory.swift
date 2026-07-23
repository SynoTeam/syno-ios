//
//  SearchCategory.swift
//  Syno
//

enum SearchCategory: String, CaseIterable, Identifiable {
  case all
  case contacts
  case notes

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .all:
      "전체"
    case .contacts:
      "연락처"
    case .notes:
      "메모"
    }
  }
}
