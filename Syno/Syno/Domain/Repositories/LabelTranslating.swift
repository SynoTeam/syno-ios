import Foundation

protocol LabelTranslating: Sendable {
  func translation(for label: String) -> String?
}

extension LabelTranslating {
  func searchTerms(for labels: [String]) -> [String] {
    labels.flatMap { label in
      guard
        let translated = translation(for: label),
        !translated.isEmpty,
        translated.localizedCaseInsensitiveCompare(label) != .orderedSame
      else {
        return [label]
      }
      return [label, translated]
    }
  }
}
