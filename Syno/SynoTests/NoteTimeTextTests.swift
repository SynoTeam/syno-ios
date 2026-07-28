import XCTest
@testable import Syno

final class NoteTimeTextTests: XCTestCase {
  func testTimeTextShowsTimeForToday() throws {
    let calendar = Calendar.current
    let now = Date()
    let date = try makeDate(
      year: calendar.component(.year, from: now),
      month: calendar.component(.month, from: now),
      day: calendar.component(.day, from: now),
      hour: 16,
      minute: 0
    )

    XCTAssertEqual(makeNote(createdAt: date).timeText, "오후 4:00")
  }

  func testTimeTextShowsMonthAndDayForAnotherDayThisYear() throws {
    let calendar = Calendar.current
    let now = Date()
    let currentMonth = calendar.component(.month, from: now)
    let currentDay = calendar.component(.day, from: now)
    let month = currentMonth == 1 && currentDay == 1 ? 2 : 1
    let day = currentMonth == 1 && currentDay == 1 ? 1 : 1
    let date = try makeDate(
      year: calendar.component(.year, from: now),
      month: month,
      day: day
    )

    XCTAssertEqual(makeNote(createdAt: date).timeText, "\(month)월 \(day)일")
  }

  func testTimeTextShowsYearForPreviousYears() throws {
    let calendar = Calendar.current
    let year = calendar.component(.year, from: Date()) - 1
    let date = try makeDate(year: year, month: 5, day: 20)

    XCTAssertEqual(makeNote(createdAt: date).timeText, "\(year)년 5월 20일")
  }

  private func makeNote(createdAt: Date) -> Note {
    Note(contactName: "테스트", content: "메모", createdAt: createdAt)
  }

  private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    minute: Int = 0
  ) throws -> Date {
    var components = DateComponents()
    components.calendar = Calendar.current
    components.timeZone = TimeZone.current
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute

    return try XCTUnwrap(components.date)
  }
}
