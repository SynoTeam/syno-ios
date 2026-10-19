import SwiftData
import XCTest
@testable import Syno

/// CloudKit 연동 모델은 유니크 제약을 걸 수 없어 같은 노트의 행이 둘 이상 생길 수 있습니다.
/// 이런 데이터가 있어도 읽기에서 앱이 죽지 않고, 저장이 중복 행을 새로 만들지 않는지 확인합니다.
final class SwiftDataDuplicateRowTests: XCTestCase {
  @MainActor
  func testNoteEmbeddingsToleratesDuplicateRowsAndKeepsNewest() async throws {
    let container = try makeContainer()
    let noteId = UUID()
    container.mainContext.insert(
      StoredNoteEmbedding(
        noteId: noteId,
        contentFingerprint: "old",
        vectorData: try encodedVector([1]),
        updatedAt: Date(timeIntervalSince1970: 100)
      )
    )
    container.mainContext.insert(
      StoredNoteEmbedding(
        noteId: noteId,
        contentFingerprint: "new",
        vectorData: try encodedVector([2]),
        updatedAt: Date(timeIntervalSince1970: 200)
      )
    )
    try container.mainContext.save()

    let embeddings = try await SwiftDataSearchEmbeddingRepository(modelContainer: container)
      .noteEmbeddings()

    XCTAssertEqual(embeddings.count, 1)
    XCTAssertEqual(embeddings[noteId]?.contentFingerprint, "new")
  }

  @MainActor
  func testSaveDoesNotInsertTwiceForSameNoteInOneBatch() async throws {
    let container = try makeContainer()
    let noteId = UUID()
    let repository = SwiftDataSearchEmbeddingRepository(modelContainer: container)

    try await repository.save([
      NoteEmbedding(noteId: noteId, contentFingerprint: "first", vector: [1], updatedAt: Date(timeIntervalSince1970: 100)),
      NoteEmbedding(noteId: noteId, contentFingerprint: "second", vector: [2], updatedAt: Date(timeIntervalSince1970: 200))
    ])

    let rows = try container.mainContext.fetch(FetchDescriptor<StoredNoteEmbedding>())
    XCTAssertEqual(rows.count, 1)
    XCTAssertEqual(rows.first?.contentFingerprint, "second")
  }

  @MainActor
  func testVoiceTranscriptFetchAllToleratesDuplicateRowsAndKeepsNewest() async throws {
    let container = try makeContainer()
    let noteId = UUID()
    container.mainContext.insert(
      StoredNoteVoiceTranscript(noteId: noteId, text: "이전 전사", transcribedAt: Date(timeIntervalSince1970: 100))
    )
    container.mainContext.insert(
      StoredNoteVoiceTranscript(noteId: noteId, text: "최근 전사", transcribedAt: Date(timeIntervalSince1970: 200))
    )
    try container.mainContext.save()

    let transcripts = try await SwiftDataNoteVoiceTranscriptRepository(modelContainer: container)
      .fetchAll()

    XCTAssertEqual(transcripts.count, 1)
    XCTAssertEqual(transcripts[noteId]?.text, "최근 전사")
  }

  @MainActor
  func testDeleteNoteEmbeddingRemovesEveryDuplicateRow() async throws {
    let container = try makeContainer()
    let noteId = UUID()
    for fingerprint in ["a", "b"] {
      container.mainContext.insert(
        StoredNoteEmbedding(
          noteId: noteId,
          contentFingerprint: fingerprint,
          vectorData: try encodedVector([1]),
          updatedAt: Date()
        )
      )
    }
    try container.mainContext.save()
    let repository = SwiftDataSearchEmbeddingRepository(modelContainer: container)

    try await repository.deleteNoteEmbedding(id: noteId)

    let rows = try container.mainContext.fetch(FetchDescriptor<StoredNoteEmbedding>())
    XCTAssertTrue(rows.isEmpty)
    let embeddings = try await repository.noteEmbeddings()
    XCTAssertTrue(embeddings.isEmpty)
  }

  @MainActor
  func testSaveRemovesOlderDuplicateEmbeddingRows() async throws {
    let container = try makeContainer()
    let noteId = UUID()
    container.mainContext.insert(
      StoredNoteEmbedding(noteId: noteId, contentFingerprint: "old", vectorData: try encodedVector([1]), updatedAt: Date(timeIntervalSince1970: 100))
    )
    container.mainContext.insert(
      StoredNoteEmbedding(noteId: noteId, contentFingerprint: "mid", vectorData: try encodedVector([2]), updatedAt: Date(timeIntervalSince1970: 200))
    )
    try container.mainContext.save()
    let repository = SwiftDataSearchEmbeddingRepository(modelContainer: container)

    try await repository.save([
      NoteEmbedding(noteId: noteId, contentFingerprint: "latest", vector: [3], updatedAt: Date(timeIntervalSince1970: 300))
    ])

    let rows = try container.mainContext.fetch(FetchDescriptor<StoredNoteEmbedding>())
    XCTAssertEqual(rows.count, 1)
    XCTAssertEqual(rows.first?.contentFingerprint, "latest")
  }

  @MainActor
  func testVoiceTranscriptFetchByNoteIdReturnsNewestWhenDuplicated() async throws {
    let container = try makeContainer()
    let noteId = UUID()
    container.mainContext.insert(
      StoredNoteVoiceTranscript(noteId: noteId, text: "이전 전사", transcribedAt: Date(timeIntervalSince1970: 100))
    )
    container.mainContext.insert(
      StoredNoteVoiceTranscript(noteId: noteId, text: "최근 전사", transcribedAt: Date(timeIntervalSince1970: 200))
    )
    try container.mainContext.save()

    let transcript = try await SwiftDataNoteVoiceTranscriptRepository(modelContainer: container)
      .fetch(noteId: noteId)

    XCTAssertEqual(transcript?.text, "최근 전사")
  }

  @MainActor
  func testVoiceTranscriptSaveRemovesOlderDuplicateRows() async throws {
    let container = try makeContainer()
    let noteId = UUID()
    container.mainContext.insert(
      StoredNoteVoiceTranscript(noteId: noteId, text: "이전 전사", transcribedAt: Date(timeIntervalSince1970: 100))
    )
    container.mainContext.insert(
      StoredNoteVoiceTranscript(noteId: noteId, text: "중간 전사", transcribedAt: Date(timeIntervalSince1970: 200))
    )
    try container.mainContext.save()

    try await SwiftDataNoteVoiceTranscriptRepository(modelContainer: container).save(
      noteId: noteId,
      result: NoteVoiceTranscriptResult(text: "새 전사"),
      transcribedAt: Date(timeIntervalSince1970: 300)
    )

    let rows = try container.mainContext.fetch(FetchDescriptor<StoredNoteVoiceTranscript>())
    XCTAssertEqual(rows.count, 1)
    XCTAssertEqual(rows.first?.text, "새 전사")
  }

  private func encodedVector(_ vector: [Double]) throws -> Data {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    return try encoder.encode(vector)
  }

  @MainActor
  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: StoredNoteEmbedding.self,
      StoredContactEmbedding.self,
      StoredNoteVoiceTranscript.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
  }
}
