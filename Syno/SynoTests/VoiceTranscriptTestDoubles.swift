import Foundation
@testable import Syno

/// 음성 전사가 필요 없는 테스트에서 의존성을 채우기 위한 빈 구현입니다.
struct EmptyVoiceTranscriptRepositoryStub: NoteVoiceTranscriptRepository {
  func fetch(noteId: Note.ID) async throws -> NoteVoiceTranscriptResult? {
    nil
  }

  func fetchAll() async throws -> [Note.ID: NoteVoiceTranscriptResult] {
    [:]
  }

  func save(
    noteId: Note.ID,
    result: NoteVoiceTranscriptResult,
    transcribedAt: Date
  ) async throws {}
}

/// 호출되면 실패하는 전사기입니다. 음성 전사를 사용하지 않는 테스트에서 사용합니다.
struct UnusedVoiceTranscriberStub: NoteVoiceTranscribing {
  func transcribe(audioData: Data) async throws -> NoteVoiceTranscriptResult {
    throw UnusedVoiceTranscriberError.notExpected
  }
}

enum UnusedVoiceTranscriberError: Error {
  case notExpected
}
