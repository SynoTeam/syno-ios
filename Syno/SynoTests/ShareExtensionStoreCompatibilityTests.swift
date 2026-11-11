import Foundation
import SwiftData
import Testing
@testable import Syno

/// 공유 확장은 앱과 같은 SQLite 파일을 따로 엽니다 (#124).
/// 확장이 같은 파일을 열고 저장해도 앱의 나머지 데이터가 유지되는지 확인합니다.
/// 예전처럼 모델 일부(`StoredContact`, `StoredNote`)만으로 열면 Core Data가 빠진 모델의 테이블을 지워 이 테스트가 실패합니다.
@MainActor
struct ShareExtensionStoreCompatibilityTests {
  /// `ShareExtensionView.openContainerAndLoadContacts`와 같은 모델 구성입니다.
  private static let extensionSchema = SynoSchema.schema

  private let storeURL: URL

  init() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("ShareExtensionStoreCompatibilityTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    storeURL = directory.appendingPathComponent("Syno.sqlite")
  }

  @Test("앱이 저장한 저장소를 확장 스키마로 열면 기존 연락처와 노트를 읽는다")
  func extensionReadsExistingContactsAndNotes() throws {
    let seed = try seedAppStore()

    let extensionContainer = try makeExtensionContainer()
    let context = extensionContainer.mainContext

    #expect(try context.fetch(FetchDescriptor<StoredContact>()).map(\.id) == [seed.contactId])
    #expect(try context.fetch(FetchDescriptor<StoredNote>()).map(\.id) == [seed.noteId])
  }

  @Test("확장 스키마로 저장소를 열기만 하고 닫아도 앱 스키마로 다시 열면 모든 데이터가 유지된다")
  func appDataSurvivesExtensionOpenOnly() throws {
    let seed = try seedAppStore()

    do {
      let extensionContainer = try makeExtensionContainer()
      _ = try extensionContainer.mainContext.fetch(FetchDescriptor<StoredContact>())
    }

    let appContainer = try makeAppContainer()
    let context = ModelContext(appContainer)
    #expect(try context.fetchCount(FetchDescriptor<UserProfile>()) == 1)
    #expect(try context.fetch(FetchDescriptor<StoredGroup>()).map(\.name) == ["스터디"])
    #expect(try context.fetch(FetchDescriptor<StoredNote>()).map(\.id) == [seed.noteId])
  }

  @Test("확장 스키마로 노트를 저장한 뒤 앱 스키마로 다시 열면 모든 데이터가 유지된다")
  func appDataSurvivesExtensionSave() throws {
    let seed = try seedAppStore()

    let sharedNoteId = try saveNoteFromExtension(contactId: seed.contactId)

    let appContainer = try makeAppContainer()
    try expectAllAppData(in: ModelContext(appContainer), seed: seed, sharedNoteId: sharedNoteId)
  }

  @Test("앱 컨테이너가 열려 있는 동안 확장이 저장해도 모든 데이터가 유지된다")
  func appDataSurvivesExtensionSaveWhileAppIsOpen() throws {
    let seed = try seedAppStore()
    let appContainer = try makeAppContainer()
    // 앱이 실행 중인 상황처럼 저장소를 한 번 읽어 열어 둔다.
    _ = try appContainer.mainContext.fetch(FetchDescriptor<StoredNote>())

    let sharedNoteId = try saveNoteFromExtension(contactId: seed.contactId)

    // 열려 있던 앱 컨테이너에서 새 컨텍스트로 읽는다.
    try expectAllAppData(in: ModelContext(appContainer), seed: seed, sharedNoteId: sharedNoteId)
    // 앱을 다시 실행한 상황처럼 새 컨테이너로도 읽는다.
    let relaunchedContainer = try makeAppContainer()
    try expectAllAppData(in: ModelContext(relaunchedContainer), seed: seed, sharedNoteId: sharedNoteId)
  }

  // MARK: - Helpers

  private struct Seed {
    let contactId: UUID
    let noteId: UUID
  }

  /// 앱 스키마로 9개 모델을 모두 한 행씩 저장하고 컨테이너를 닫습니다.
  private func seedAppStore() throws -> Seed {
    let container = try makeAppContainer()
    let context = container.mainContext
    let contactId = UUID()
    let noteId = UUID()

    context.insert(UserProfile(familyName: "김", givenName: "테스트"))
    context.insert(StoredGroup(name: "스터디", sortIndex: 0))
    context.insert(
      StoredContact(
        id: contactId,
        name: "테스트 연락처",
        role: "",
        company: "",
        email: "",
        phone: "",
        url: "",
        address: "",
        birthday: nil,
        anniversary: nil,
        socialLinks: [],
        group: "스터디",
        note: "",
        profileImageData: nil,
        isFavorite: false,
        isMe: false
      )
    )
    context.insert(
      StoredNote(
        id: noteId,
        contactId: contactId,
        contactName: "테스트 연락처",
        content: "앱에서 쓴 노트",
        imageData: nil,
        profileImageData: nil,
        isFavorite: false
      )
    )
    context.insert(StoredNoteImageAnalysis(noteId: noteId, labels: ["cat"], ocrText: "OCR"))
    context.insert(
      StoredNoteLinkPreview(
        noteId: noteId,
        result: NoteLinkPreviewResult(
          title: "링크",
          imageURL: nil,
          siteURL: URL(string: "https://example.com")!
        )
      )
    )
    context.insert(StoredNoteVoiceTranscript(noteId: noteId, text: "전사"))
    context.insert(
      StoredNoteEmbedding(noteId: noteId, contentFingerprint: "note", vectorData: Data([1]), updatedAt: Date())
    )
    context.insert(
      StoredContactEmbedding(contactId: contactId, contentFingerprint: "contact", vectorData: Data([2]), updatedAt: Date())
    )
    try context.save()

    return Seed(contactId: contactId, noteId: noteId)
  }

  /// 공유 확장처럼 두 모델로 저장소를 열어 노트 하나를 저장하고 컨테이너를 닫습니다.
  private func saveNoteFromExtension(contactId: UUID) throws -> UUID {
    let container = try makeExtensionContainer()
    let context = container.mainContext
    let noteId = UUID()
    context.insert(
      StoredNote(
        id: noteId,
        contactId: contactId,
        contactName: "테스트 연락처",
        content: "공유 확장에서 저장한 노트",
        imageData: nil,
        profileImageData: nil,
        isFavorite: false
      )
    )
    try context.save()
    return noteId
  }

  private func expectAllAppData(in context: ModelContext, seed: Seed, sharedNoteId: UUID) throws {
    #expect(try context.fetchCount(FetchDescriptor<UserProfile>()) == 1)
    #expect(try context.fetch(FetchDescriptor<StoredGroup>()).map(\.name) == ["스터디"])
    #expect(try context.fetch(FetchDescriptor<StoredContact>()).map(\.id) == [seed.contactId])
    #expect(Set(try context.fetch(FetchDescriptor<StoredNote>()).map(\.id)) == [seed.noteId, sharedNoteId])
    #expect(try context.fetch(FetchDescriptor<StoredNoteImageAnalysis>()).map(\.noteId) == [seed.noteId])
    #expect(try context.fetch(FetchDescriptor<StoredNoteLinkPreview>()).map(\.noteId) == [seed.noteId])
    #expect(try context.fetch(FetchDescriptor<StoredNoteVoiceTranscript>()).map(\.noteId) == [seed.noteId])
    #expect(try context.fetch(FetchDescriptor<StoredNoteEmbedding>()).map(\.noteId) == [seed.noteId])
    #expect(try context.fetch(FetchDescriptor<StoredContactEmbedding>()).map(\.contactId) == [seed.contactId])
  }

  // 테스트 호스트의 CloudKit 권한으로 동기화를 시도하지 않도록 두 구성 모두 `.none`을 지정한다.
  private func makeAppContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(
      schema: AppContainer.schema,
      url: storeURL,
      cloudKitDatabase: .none
    )
    return try ModelContainer(for: AppContainer.schema, configurations: configuration)
  }

  private func makeExtensionContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(
      schema: Self.extensionSchema,
      url: storeURL,
      cloudKitDatabase: .none
    )
    return try ModelContainer(for: Self.extensionSchema, configurations: configuration)
  }
}
