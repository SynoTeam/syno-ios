//
//  SearchCategory.swift
//  Syno
//

enum SearchCategory: String, CaseIterable, Identifiable {
  case all
  case text
  case photo
  case link
  case voice

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .all:
      "전체"
    case .text: "텍스트"
    case .photo: "사진"
    case .link: "링크"
    case .voice: "음성메모"
    }
  }
}
