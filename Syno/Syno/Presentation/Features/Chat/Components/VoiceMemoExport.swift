import CoreTransferable
import Foundation

/// 아카이브에서 음성 메모를 기기에 저장할 때 쓰는 파일 이름 규칙입니다 (#144).
enum VoiceMemoExport {
  /// 제목에 오디오 형식에 맞는 확장자를 붙입니다. 가져온 파일은 형식이 제각각이라 데이터 머리 부분으로 판단합니다.
  nonisolated static func fileName(title: String, audioData: Data) -> String {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let base = trimmed.isEmpty ? "음성 메모" : trimmed
      .replacingOccurrences(of: "/", with: "-")
      .replacingOccurrences(of: ":", with: "-")
    let ext = fileExtension(for: audioData)
    return "\(truncated(base, maxUTF8Bytes: maxFileNameBytes - ext.utf8.count - 1)).\(ext)"
  }

  /// 파일 이름 길이 상한입니다. 파일 시스템 한도(255바이트)보다 여유를 둡니다.
  /// 전사 첫 줄이 제목이 되면 아주 길 수 있어, 그대로 쓰면 파일을 만들지 못합니다.
  private nonisolated static let maxFileNameBytes = 200

  /// 화면에 보이는 글자 단위로 앞에서부터 담아 UTF-8 바이트 상한을 넘지 않게 자릅니다.
  private nonisolated static func truncated(_ text: String, maxUTF8Bytes: Int) -> String {
    guard text.utf8.count > maxUTF8Bytes else { return text }
    var result = ""
    var bytes = 0
    for character in text {
      let size = String(character).utf8.count
      guard bytes + size <= maxUTF8Bytes else { break }
      result.append(character)
      bytes += size
    }
    return result
  }

  /// 데이터 머리 부분으로 판단한 오디오 확장자입니다. 복사할 때 형식을 알리는 데도 씁니다.
  nonisolated static func fileExtension(for data: Data) -> String {
    let bytes = [UInt8](data.prefix(12))
    func ascii(_ range: Range<Int>) -> String? {
      guard bytes.count >= range.upperBound else { return nil }
      return String(bytes: bytes[range], encoding: .ascii)
    }
    if ascii(4..<8) == "ftyp" { return "m4a" }
    if ascii(0..<3) == "ID3" { return "mp3" }
    if bytes.count >= 2, bytes[0] == 0xFF, bytes[1] & 0xE0 == 0xE0 { return "mp3" }
    if ascii(0..<4) == "RIFF", ascii(8..<12) == "WAVE" { return "wav" }
    if ascii(0..<4) == "caff" { return "caf" }
    if ascii(0..<4) == "FORM", ascii(8..<12) == "AIFF" { return "aiff" }
    // 앱에서 녹음한 형식(AAC)으로 봅니다.
    return "m4a"
  }
}

/// 공유 글에 들어가는 음성 메모 하나입니다.
struct VoiceMemoShareEntry: Sendable {
  let title: String
  /// 변환 텍스트입니다. 아직 변환하지 않았거나 실패했으면 nil입니다.
  let transcript: String?
}

extension VoiceMemoExport {
  /// 음성 메모 공유는 오디오 대신 변환 텍스트로 합니다 (#144).
  /// 한 개면 변환 텍스트만, 여러 개면 메모마다 "제목\n변환 텍스트"를 빈 줄로 나눠 잇습니다.
  /// 변환 텍스트가 없으면 제목을 씁니다.
  nonisolated static func shareText(_ entries: [VoiceMemoShareEntry]) -> String {
    func transcript(of entry: VoiceMemoShareEntry) -> String? {
      guard let text = entry.transcript?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
      return text
    }
    if entries.count == 1, let entry = entries.first {
      return transcript(of: entry) ?? entry.title
    }
    return entries
      .map { entry in [entry.title, transcript(of: entry)].compactMap { $0 }.joined(separator: "\n") }
      .joined(separator: "\n\n")
  }
}

/// 음성 메모 공유 항목입니다. 공유할 앱을 고르면 그때 `VoiceMemoExport.shareText`로 글을 만듭니다 (#144).
struct VoiceMemoShareItem: Transferable {
  let entries: [VoiceMemoShareEntry]

  var text: String { VoiceMemoExport.shareText(entries) }

  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation(exporting: \.text)
  }
}

/// 복사할 음성 메모 파일 정보입니다. 붙여 넣는 순간에 임시 파일을 만듭니다 (#144).
struct VoiceMemoTransferItem {
  let noteID: UUID
  let audioData: Data
  let fileName: String

  init(note: Note) {
    noteID = note.id
    audioData = note.voiceMemoData ?? Data()
    fileName = VoiceMemoExport.fileName(title: note.content, audioData: audioData)
  }
}
