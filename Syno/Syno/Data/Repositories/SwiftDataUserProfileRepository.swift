import Foundation
import OSLog
import SwiftData

@MainActor
final class SwiftDataUserProfileRepository: UserProfileRepository {
  private let modelContext: ModelContext
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Syno",
    category: "UserProfileRepository"
  )

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func save(familyName: String, givenName: String) throws {
    do {
      modelContext.insert(UserProfile(familyName: familyName, givenName: givenName))
      try modelContext.save()
    } catch {
      modelContext.rollback()
      logger.error("Failed to save user profile: \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }
}
