import Foundation

enum SearchDocumentKind: String, Hashable, Sendable {
  case contact
  case note
}

struct SearchDocumentKey: Hashable, Sendable {
  let kind: SearchDocumentKind
  let sourceId: UUID
}

struct SearchDocument: Sendable {
  static let minimumSemanticTextLength = 5

  let key: SearchDocumentKey
  let text: String
  let isSemanticEligible: Bool

  static func contact(id: UUID, text: String) -> SearchDocument {
    SearchDocument(
      key: SearchDocumentKey(kind: .contact, sourceId: id),
      text: text,
      isSemanticEligible: isLongEnoughForSemanticSearch(text)
    )
  }

  static func note(id: UUID, text: String) -> SearchDocument {
    SearchDocument(
      key: SearchDocumentKey(kind: .note, sourceId: id),
      text: text,
      isSemanticEligible: isLongEnoughForSemanticSearch(text)
    )
  }

  private static func isLongEnoughForSemanticSearch(_ text: String) -> Bool {
    text.filter { !$0.isWhitespace }.count >= minimumSemanticTextLength
  }
}
