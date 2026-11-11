import SwiftData

/// 앱과 공유 확장이 같은 저장소(App Group의 Syno.sqlite)를 열 때 쓰는 모델 목록입니다.
/// 이 파일과 모델 파일은 두 타깃이 함께 컴파일합니다. 모델을 추가하면 여기에만 추가합니다.
/// 모델 일부만으로 저장소를 열면 Core Data가 빠진 모델의 테이블을 지우므로, 두 타깃 모두 반드시 이 목록 전체로 엽니다 (#124).
enum SynoSchema {
  static var schema: Schema {
    Schema([
      UserProfile.self,
      StoredContact.self,
      StoredGroup.self,
      StoredNote.self,
      StoredContactEmbedding.self,
      StoredNoteEmbedding.self,
      StoredNoteImageAnalysis.self,
      StoredNoteLinkPreview.self,
      StoredNoteVoiceTranscript.self
    ])
  }
}
