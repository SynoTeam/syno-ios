import Foundation

@MainActor
protocol ContactRepository {
  func fetchAll() throws -> [Contact]
  func save(_ contact: Contact) throws
  func delete(id: Contact.ID) throws
}
