import Foundation
import Testing
@testable import Syno

/// 공유·파일 앱 저장용 임시 파일 규칙입니다 (#144).
/// 사용자에게 보이는 파일 이름은 정한 이름 그대로여야 하고, 노트를 지우면 임시 파일도 지워져야 합니다.
@MainActor
struct FileTransferURLTests {
  @Test("임시 파일 이름은 정한 이름 그대로다(노트 ID가 붙지 않는다)")
  func fileNameIsExact() async throws {
    let noteID = UUID()
    defer { FileTransferURL.removeTemporaryFileNow(for: noteID) }

    let url = try #require(await FileTransferURL.prepare(data: Data([1, 2, 3]), name: "회의 녹음.m4a", noteID: noteID))

    #expect(url.lastPathComponent == "회의 녹음.m4a")
    #expect(try Data(contentsOf: url) == Data([1, 2, 3]))
  }

  @Test("같은 이름이라도 노트가 다르면 서로 덮어쓰지 않는다")
  func sameNameDifferentNotes() async throws {
    let first = UUID()
    let second = UUID()
    defer {
      FileTransferURL.removeTemporaryFileNow(for: first)
      FileTransferURL.removeTemporaryFileNow(for: second)
    }

    let firstURL = try #require(await FileTransferURL.prepare(data: Data([1]), name: "메모.m4a", noteID: first))
    let secondURL = try #require(await FileTransferURL.prepare(data: Data([2]), name: "메모.m4a", noteID: second))

    #expect(firstURL != secondURL)
    #expect(try Data(contentsOf: firstURL) == Data([1]))
    #expect(try Data(contentsOf: secondURL) == Data([2]))
  }

  @Test("제목이 바뀌어 새 이름으로 준비하면 예전 이름의 파일은 지운다")
  func renameRemovesOldFile() async throws {
    let noteID = UUID()
    defer { FileTransferURL.removeTemporaryFileNow(for: noteID) }

    let oldURL = try #require(await FileTransferURL.prepare(data: Data([1]), name: "무제-1.m4a", noteID: noteID))
    let newURL = try #require(await FileTransferURL.prepare(data: Data([1]), name: "회의 녹음.m4a", noteID: noteID))

    #expect(newURL.lastPathComponent == "회의 녹음.m4a")
    #expect(!FileManager.default.fileExists(atPath: oldURL.path))
  }

  @Test("덮어쓰기를 요청하면 이름과 크기가 같아도 새 내용으로 쓴다(복사용 폴더)")
  func overwriteReplacesSameSizedFile() async throws {
    let folderID = UUID()
    defer { FileTransferURL.removeTemporaryFileNow(for: folderID) }

    _ = await FileTransferURL.prepare(data: Data([1, 1]), name: "메모.m4a", noteID: folderID, overwrite: true)
    let url = try #require(await FileTransferURL.prepare(data: Data([2, 2]), name: "메모.m4a", noteID: folderID, overwrite: true))

    #expect(try Data(contentsOf: url) == Data([2, 2]))
  }

  @Test("노트를 지우면 그 노트의 임시 파일도 지운다")
  func removeDeletesFiles() async throws {
    let noteID = UUID()
    let url = try #require(await FileTransferURL.prepare(data: Data([1]), name: "메모.m4a", noteID: noteID))

    FileTransferURL.removeTemporaryFileNow(for: noteID)

    #expect(!FileManager.default.fileExists(atPath: url.path))
  }
}
