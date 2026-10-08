import Foundation

@MainActor
protocol NoteRepository {
  func fetch(contactId: UUID?) throws -> [Note]
  func save(_ note: Note) throws
  func delete(id: Note.ID) throws

  /// 연락처는 유지한 채, 해당 연락처들에 저장된 노트와 연결 데이터만 한 트랜잭션으로 모두 삭제합니다.
  func deleteAll(contactIds: [UUID]) throws
}
