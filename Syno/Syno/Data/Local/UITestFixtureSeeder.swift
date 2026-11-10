#if DEBUG
import Foundation
import SwiftData
import UIKit

/// UI 테스트가 항상 같은 화면에서 시작하도록 메모리 저장소에 고정된 샘플 데이터를 넣습니다.
/// 실행 인자 `-UITestFixtures`로 앱을 띄울 때만 쓰고, 출시 빌드에는 포함하지 않습니다.
enum UITestFixtureSeeder {
  /// UI 테스트가 화면에서 찾는 이름과 문구입니다. 테스트 코드와 같은 값을 씁니다.
  enum Text {
    static let contactName = "테스트 연락처"
    static let oldestMessage = "첫 번째 메시지"
    static let latestMessage = "마지막 메시지"
    /// 사용자 설정 순서입니다. 가나다순(가족, 스터디, 회사)과 다르게 둬서 두 정렬을 구분할 수 있게 합니다.
    static let groupsInCustomOrder = ["스터디", "회사", "가족"]
  }

  /// 대화 길이입니다. 채팅방 진입 위치와 스크롤을 확인할 수 있을 만큼 화면보다 길게 둡니다.
  private static let messageCount = 40

  static func seed(into context: ModelContext) {
    // 온보딩을 건너뛰고 메인 탭에서 시작하게 한다.
    context.insert(UserProfile(familyName: "테", givenName: "스터"))

    for (index, name) in Text.groupsInCustomOrder.enumerated() {
      context.insert(StoredGroup(name: name, sortIndex: index))
    }

    let contact = Contact(name: Text.contactName, role: "", company: "", group: Text.groupsInCustomOrder[0])
    context.insert(StoredContact(contact: contact))

    let baseDate = Date(timeIntervalSince1970: 1_793_000_000)
    for index in 0..<messageCount {
      let createdAt = baseDate.addingTimeInterval(TimeInterval(index * 60 * 60))
      let note = makeNote(index: index, contact: contact, createdAt: createdAt)
      context.insert(StoredNote(note: note))

      if let url = linkURL(for: index) {
        context.insert(
          StoredNoteLinkPreview(
            noteId: note.id,
            result: NoteLinkPreviewResult(title: "샘플 링크 \(index)", imageURL: nil, siteURL: url)
          )
        )
      }
      if note.voiceMemoData != nil {
        context.insert(StoredNoteVoiceTranscript(noteId: note.id, text: "음성 메모 변환 결과 \(index)"))
      }
    }

    try? context.save()
  }

  /// 텍스트, 링크, 사진, 음성 메모가 섞이도록 순서에 따라 종류를 정합니다.
  private static func makeNote(index: Int, contact: Contact, createdAt: Date) -> Note {
    let isFirst = index == 0
    let isLast = index == messageCount - 1

    if isFirst || isLast {
      return Note(
        contactId: contact.id,
        contactName: contact.name,
        content: isFirst ? Text.oldestMessage : Text.latestMessage,
        createdAt: createdAt
      )
    }
    if let url = linkURL(for: index) {
      return Note(contactId: contact.id, contactName: contact.name, content: url.absoluteString, createdAt: createdAt)
    }
    if index % 7 == 0 {
      return Note(
        contactId: contact.id,
        contactName: contact.name,
        content: "사진",
        createdAt: createdAt,
        imageData: sampleImageData
      )
    }
    if index % 11 == 0 {
      return Note(
        contactId: contact.id,
        contactName: contact.name,
        content: "음성 메모",
        createdAt: createdAt,
        voiceMemoData: Data([0x00]),
        voiceMemoDuration: 3
      )
    }
    return Note(
      contactId: contact.id,
      contactName: contact.name,
      content: "샘플 메시지 \(index)",
      createdAt: createdAt
    )
  }

  private static func linkURL(for index: Int) -> URL? {
    guard index % 5 == 0, index != 0 else {
      return nil
    }
    return URL(string: "https://example.com/article/\(index)")
  }

  private static let sampleImageData: Data? = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
    .image { context in
      UIColor.systemTeal.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
    }
    .jpegData(compressionQuality: 0.8)
}
#endif
