@MainActor
protocol UserProfileRepository {
  func save(familyName: String, givenName: String) throws
}
