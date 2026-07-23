//
//  NoteSortOrder.swift
//  Syno
//

enum NoteSortOrder: String, CaseIterable, Identifiable {
  case newest
  case name

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .newest:
      "최신순"
    case .name:
      "이름순"
    }
  }

  var systemImage: String {
    switch self {
    case .newest:
      "clock"
    case .name:
      "textformat"
    }
  }
}
