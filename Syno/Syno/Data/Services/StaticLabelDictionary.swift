import Foundation
import OSLog

struct StaticLabelDictionary: LabelTranslating {
  private let translations: [String: String]

  init(bundle: Bundle = .main) {
    let logger = Logger(
      subsystem: Bundle.main.bundleIdentifier ?? "Syno",
      category: "StaticLabelDictionary"
    )
    guard
      let url = bundle.url(
        forResource: "VisionLabelTranslations",
        withExtension: "json"
      )
    else {
      logger.error("VisionLabelTranslations.json is missing from the bundle")
      translations = [:]
      return
    }

    do {
      let data = try Data(contentsOf: url)
      let decoded = try JSONDecoder().decode(
        [String: String].self,
        from: data
      )
      translations = decoded.reduce(into: [:]) {
        $0[Self.normalized($1.key)] = $1.value
      }
    } catch {
      logger.error(
        "Failed to load Vision label translations: \(error.localizedDescription, privacy: .public)"
      )
      translations = [:]
    }
  }

  init(translations: [String: String]) {
    self.translations = translations.reduce(into: [:]) {
      $0[Self.normalized($1.key)] = $1.value
    }
  }

  func translation(for label: String) -> String? {
    translations[Self.normalized(label)]
  }

  private static func normalized(_ label: String) -> String {
    label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }
}
