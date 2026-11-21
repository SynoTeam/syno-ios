import Foundation
import Testing
@testable import Syno

/// 아카이브 음성 목록의 시간·진행률·저장 파일 이름 규칙입니다 (#144).
@MainActor
struct VoiceMemoArchiveFormatTests {
  @Test("재생 시간은 분:초 두 자리씩 표시한다", arguments: [
    (0.0, "00:00"),
    (0.9, "00:00"),
    (23.4, "00:23"),
    (59.99, "00:59"),
    (60.0, "01:00"),
    (605.0, "10:05"),
    // 한 시간이 넘어도 분으로 이어서 센다
    (3_725.0, "62:05"),
    // 잘못된 값은 0으로 본다
    (-3.0, "00:00"),
    (Double.nan, "00:00"),
  ])
  func playbackTimeText(seconds: Double, expected: String) {
    #expect(ArchiveFormatters.playbackTimeText(seconds) == expected)
  }

  @Test("길이가 없으면 00:00이다")
  func playbackTimeTextNil() {
    #expect(ArchiveFormatters.playbackTimeText(nil) == "00:00")
  }

  @Test("진행 막대 비율은 0과 1 사이로 자른다", arguments: [
    (0.0, 10.0, 0.0),
    (5.0, 10.0, 0.5),
    (10.0, 10.0, 1.0),
    (12.0, 10.0, 1.0),
    (-1.0, 10.0, 0.0),
    // 길이를 모르면 막대를 채우지 않는다
    (3.0, 0.0, 0.0),
    (3.0, -1.0, 0.0),
  ])
  func progress(elapsed: Double, duration: Double, expected: Double) {
    #expect(ArchiveFormatters.playbackProgress(elapsed: elapsed, duration: duration) == expected)
  }

  @Test("저장 파일 이름은 제목에 오디오 형식에 맞는 확장자를 붙인다", arguments: [
    // 앱에서 녹음한 AAC(m4a): 5번째 바이트부터 "ftyp"
    ("회의 녹음", Data([0, 0, 0, 0x20]) + Data("ftypM4A ".utf8), "회의 녹음.m4a"),
    ("인터뷰", Data("ID3".utf8) + Data([4, 0]), "인터뷰.mp3"),
    ("인터뷰", Data([0xFF, 0xFB, 0x90, 0x00]), "인터뷰.mp3"),
    ("메모", Data("RIFF".utf8) + Data([0, 0, 0, 0]) + Data("WAVE".utf8), "메모.wav"),
    ("메모", Data("caff".utf8) + Data([0, 1]), "메모.caf"),
    ("메모", Data("FORM".utf8) + Data([0, 0, 0, 0]) + Data("AIFF".utf8), "메모.aiff"),
    // 알 수 없는 형식은 앱 녹음 형식(m4a)으로 본다
    ("메모", Data([0x00]), "메모.m4a"),
  ])
  func fileName(title: String, data: Data, expected: String) {
    #expect(VoiceMemoExport.fileName(title: title, audioData: data) == expected)
  }

  @Test("파일 이름에 쓸 수 없는 문자는 바꾸고, 빈 제목은 기본 이름을 쓴다", arguments: [
    ("a/b:c", "a-b-c.m4a"),
    ("   ", "음성 메모.m4a"),
    ("", "음성 메모.m4a"),
    ("  앞뒤 공백  ", "앞뒤 공백.m4a"),
  ])
  func fileNameSanitized(title: String, expected: String) {
    #expect(VoiceMemoExport.fileName(title: title, audioData: Data()) == expected)
  }

  @Test("공유 글: 한 개는 변환 텍스트만, 여러 개는 제목과 변환 텍스트를 빈 줄로 나눠 잇는다", arguments: [
    // 한 개: 변환 텍스트 그대로
    ([VoiceMemoShareEntry(title: "회의", transcript: "다음 주 일정 확정")], "다음 주 일정 확정"),
    // 한 개인데 변환 결과가 없거나 비었으면 제목
    ([VoiceMemoShareEntry(title: "회의", transcript: nil)], "회의"),
    ([VoiceMemoShareEntry(title: "회의", transcript: "  \n ")], "회의"),
    // 여러 개: 제목 줄 + 변환 텍스트, 메모 사이는 빈 줄
    ([
      VoiceMemoShareEntry(title: "회의", transcript: "일정 확정"),
      VoiceMemoShareEntry(title: "인터뷰", transcript: "포트폴리오 질문"),
    ], "회의\n일정 확정\n\n인터뷰\n포트폴리오 질문"),
    // 여러 개 중 변환 결과가 없는 메모는 제목만
    ([
      VoiceMemoShareEntry(title: "회의", transcript: nil),
      VoiceMemoShareEntry(title: "인터뷰", transcript: "질문"),
    ], "회의\n\n인터뷰\n질문"),
    ([], ""),
  ])
  func shareText(entries: [VoiceMemoShareEntry], expected: String) {
    #expect(VoiceMemoExport.shareText(entries) == expected)
  }
}
