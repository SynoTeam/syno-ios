import SwiftData
import XCTest
@testable import Syno

final class AccountResetServiceTests: XCTestCase {
  @MainActor
  func testClearTemporaryDataPreservesOriginalNotesAndAccountData() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    let note = StoredNote(
      id: UUID(),
      contactId: nil,
      contactName: "테스트",
      content: "원본 노트",
      imageData: Data(repeating: 1, count: 1_024),
      profileImageData: nil,
      isFavorite: false
    )
    context.insert(note)
    context.insert(UserProfile(familyName: "홍", givenName: "길동"))
    context.insert(StoredContactEmbedding(contactId: UUID(), contentFingerprint: "contact", vectorData: Data(), updatedAt: .now))
    context.insert(StoredNoteEmbedding(noteId: note.id, contentFingerprint: "note", vectorData: Data(), updatedAt: .now))
    context.insert(StoredNoteImageAnalysis(noteId: note.id, labels: ["document"], ocrText: "원본"))
    try context.save()

    try AccountResetService(modelContext: context).clearTemporaryData()

    XCTAssertEqual(try context.fetch(FetchDescriptor<StoredNote>()).count, 1)
    XCTAssertEqual(try context.fetch(FetchDescriptor<StoredNote>()).first?.imageData, note.imageData)
    XCTAssertEqual(try context.fetch(FetchDescriptor<UserProfile>()).count, 1)
    XCTAssertTrue(try context.fetch(FetchDescriptor<StoredContactEmbedding>()).isEmpty)
    XCTAssertTrue(try context.fetch(FetchDescriptor<StoredNoteEmbedding>()).isEmpty)
    XCTAssertTrue(try context.fetch(FetchDescriptor<StoredNoteImageAnalysis>()).isEmpty)
  }

  @MainActor
  func testResetAllDataDeletesAccountAndOriginalData() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    context.insert(StoredContact(contact: Contact(name: "테스트", role: "", company: "")))
    context.insert(StoredGroup(name: "테스트 그룹", sortIndex: 0))
    context.insert(StoredNote(id: UUID(), contactId: nil, contactName: "", content: "노트", imageData: Data(), profileImageData: nil, isFavorite: false))
    context.insert(UserProfile(familyName: "홍", givenName: "길동"))
    context.insert(StoredContactEmbedding(contactId: UUID(), contentFingerprint: "contact", vectorData: Data(), updatedAt: .now))
    context.insert(StoredNoteEmbedding(noteId: UUID(), contentFingerprint: "note", vectorData: Data(), updatedAt: .now))
    context.insert(StoredNoteImageAnalysis(noteId: UUID(), labels: [], ocrText: ""))
    try context.save()

    try AccountResetService(modelContext: context).resetAllData()

    XCTAssertTrue(try context.fetch(FetchDescriptor<StoredContact>()).isEmpty)
    XCTAssertTrue(try context.fetch(FetchDescriptor<StoredGroup>()).isEmpty)
    XCTAssertTrue(try context.fetch(FetchDescriptor<StoredNote>()).isEmpty)
    XCTAssertTrue(try context.fetch(FetchDescriptor<UserProfile>()).isEmpty)
    XCTAssertTrue(try context.fetch(FetchDescriptor<StoredContactEmbedding>()).isEmpty)
    XCTAssertTrue(try context.fetch(FetchDescriptor<StoredNoteEmbedding>()).isEmpty)
    XCTAssertTrue(try context.fetch(FetchDescriptor<StoredNoteImageAnalysis>()).isEmpty)
  }

  @MainActor
  func testNoteStorageUsageSumsOnlyOriginalNoteImageData() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    context.insert(StoredNote(id: UUID(), contactId: nil, contactName: "", content: "", imageData: Data(repeating: 0, count: 512), profileImageData: Data(repeating: 0, count: 100), isFavorite: false))
    context.insert(StoredNote(id: UUID(), contactId: nil, contactName: "", content: "", imageData: Data(repeating: 0, count: 256), profileImageData: nil, isFavorite: false))
    try context.save()

    XCTAssertEqual(try AccountResetService(modelContext: context).noteStorageUsage(), 768)
  }

  @MainActor
  func testMediaUsageByContactExcludesUnlinkedNotesAndGroupsByContact() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    let contact = Contact(name: "김테스트", role: "", company: "")
    context.insert(StoredContact(contact: contact))
    context.insert(StoredNote(id: UUID(), contactId: contact.id, contactName: contact.name, content: "", imageData: Data(repeating: 0, count: 512), profileImageData: nil, isFavorite: false))
    context.insert(StoredNote(id: UUID(), contactId: contact.id, contactName: contact.name, content: "", imageData: Data(repeating: 0, count: 256), profileImageData: nil, isFavorite: false))
    context.insert(StoredNote(id: UUID(), contactId: nil, contactName: "", content: "", imageData: Data(repeating: 0, count: 128), profileImageData: nil, isFavorite: false))
    try context.save()

    let usages = try AccountResetService(modelContext: context).mediaUsageByContact()

    XCTAssertEqual(usages.count, 1)
    XCTAssertEqual(usages.first?.contact.id, contact.id)
    XCTAssertEqual(usages.first?.bytes, 768)
  }

  @MainActor
  func testDeleteNoteMediaPreservesTextAndOnlyClearsTargetContact() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    let firstContact = Contact(name: "첫 번째", role: "", company: "")
    let secondContact = Contact(name: "두 번째", role: "", company: "")
    let firstNote = StoredNote(id: UUID(), contactId: firstContact.id, contactName: firstContact.name, content: "유지할 텍스트", imageData: Data(repeating: 0, count: 512), profileImageData: nil, isFavorite: false)
    let secondNote = StoredNote(id: UUID(), contactId: secondContact.id, contactName: secondContact.name, content: "다른 텍스트", imageData: Data(repeating: 0, count: 256), profileImageData: nil, isFavorite: false)
    context.insert(firstNote)
    context.insert(secondNote)
    try context.save()

    try AccountResetService(modelContext: context).deleteNoteMedia(forContactId: firstContact.id)

    let notes = try context.fetch(FetchDescriptor<StoredNote>())
    XCTAssertEqual(notes.first { $0.id == firstNote.id }?.content, "유지할 텍스트")
    XCTAssertNil(notes.first { $0.id == firstNote.id }?.imageData)
    XCTAssertEqual(notes.first { $0.id == secondNote.id }?.imageData?.count, 256)
  }

  @MainActor
  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: UserProfile.self,
      StoredContact.self,
      StoredGroup.self,
      StoredNote.self,
      StoredContactEmbedding.self,
      StoredNoteEmbedding.self,
      StoredNoteImageAnalysis.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
  }
}
