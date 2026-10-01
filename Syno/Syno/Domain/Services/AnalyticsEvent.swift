import Foundation

/// 트래킹하는 이벤트 이름과 속성 키를 한 곳에 모아둡니다. 오타/중복 방지 목적입니다.
enum AnalyticsEvent {
  static let onboardingCompleted = "Onboarding Completed"
  static let screenViewed = "Screen Viewed"
  static let contactCreated = "Contact Created"
  static let contactDeleted = "Contact Deleted"
  static let noteSent = "Note Sent"
  static let noteDeleted = "Note Deleted"
  static let searchPerformed = "Search Performed"
  static let archiveCategoryOpened = "Archive Category Opened"
  static let accountDataReset = "Account Data Reset"

  enum Property {
    static let screenName = "screen_name"
    static let contentType = "content_type"
    static let category = "category"
    static let hasResults = "has_results"
    static let resetType = "reset_type"
  }

  /// `Note Sent`/`Note Deleted`의 `content_type` 값입니다.
  enum ContentType: String {
    case text
    case photo
    case voice
    case file
    case link
  }
}
