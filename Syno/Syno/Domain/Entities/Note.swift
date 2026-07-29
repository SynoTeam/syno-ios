//
//  Note.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import Foundation

/// 연락처에 남긴 메모를 나타내는 도메인 모델입니다.
struct Note: Identifiable, Equatable, Hashable {
  let id: UUID
  var contactId: UUID?
  var contactName: String
  var content: String
  var createdAt: Date
  var imageData: Data?
  var profileImageData: Data?
  var isFavorite: Bool
  var isPinned: Bool

  var timeText: String {
    let calendar = Calendar.current

    if calendar.isDateInToday(createdAt) {
      return Self.timeFormatter.string(from: createdAt)
    }

    if calendar.isDate(createdAt, equalTo: Date(), toGranularity: .year) {
      return Self.monthDayFormatter.string(from: createdAt)
    }

    return Self.yearMonthDayFormatter.string(from: createdAt)
  }

  /// 날짜와 무관하게 시각만 표시합니다. 날짜별로 묶어 보여주는 채팅 화면에서 사용합니다.
  var clockTimeText: String {
    Self.timeFormatter.string(from: createdAt)
  }

  var contact: Contact {
    Contact(
      id: contactId ?? id,
      name: contactName,
      role: "",
      company: "",
      profileImageData: profileImageData
    )
  }

  init(
    id: UUID = UUID(),
    contactId: UUID? = nil,
    contactName: String,
    content: String,
    createdAt: Date = Date(),
    imageData: Data? = nil,
    profileImageData: Data? = nil,
    isFavorite: Bool = false,
    isPinned: Bool = false
  ) {
    self.id = id
    self.contactId = contactId
    self.contactName = contactName
    self.content = content
    self.createdAt = createdAt
    self.imageData = imageData
    self.profileImageData = profileImageData
    self.isFavorite = isFavorite
    self.isPinned = isPinned
  }

  private static let timeFormatter = makeFormatter("a h:mm")
  private static let monthDayFormatter = makeFormatter("M월 d일")
  private static let yearMonthDayFormatter = makeFormatter("yyyy년 M월 d일")

  private static func makeFormatter(_ dateFormat: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = dateFormat
    return formatter
  }
}
