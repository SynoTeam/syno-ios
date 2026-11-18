import CoreGraphics
import Testing
@testable import Syno

/// 채팅 사진 업로드와 단일 사진 말풍선의 표시 규칙입니다 (#138).
@MainActor
struct ChatPhotoLayoutTests {
  @Test("단일 사진은 가로 220·세로 300 안에서 원본 비율을 유지하고, 짧은 변은 120보다 작아지지 않는다", arguments: [
    // 정사각형
    (CGSize(width: 1000, height: 1000), CGSize(width: 220, height: 220)),
    // 가로 4:3
    (CGSize(width: 4000, height: 3000), CGSize(width: 220, height: 165)),
    // 세로 3:4 → 가로가 먼저 220에 닿는다
    (CGSize(width: 3000, height: 4000), CGSize(width: 220, height: 293)),
    // 세로 9:16 → 세로가 먼저 300에 닿는다
    (CGSize(width: 900, height: 1600), CGSize(width: 169, height: 300)),
    // 작은 사진도 같은 크기 안으로 키워 맞춘다
    (CGSize(width: 100, height: 100), CGSize(width: 220, height: 220)),
    // 파노라마 → 세로 최소 120, 넘치는 부분은 잘린다
    (CGSize(width: 4000, height: 1000), CGSize(width: 220, height: 120)),
    // 아주 긴 세로 사진 → 가로 최소 120
    (CGSize(width: 1000, height: 4000), CGSize(width: 120, height: 300)),
    // 크기를 알 수 없으면 정사각형
    (CGSize.zero, CGSize(width: 220, height: 220)),
  ])
  func singlePhotoSize(imageSize: CGSize, expected: CGSize) {
    #expect(ChatPhotoLayout.singlePhotoSize(for: imageSize) == expected)
  }

  @Test("업로드 확인 시트의 장수 칩은 2장 이상일 때만 보인다", arguments: [
    (0, nil),
    (1, nil),
    (2, "2장"),
    (30, "30장"),
  ] as [(Int, String?)])
  func countChipText(count: Int, expected: String?) {
    #expect(ChatPhotoLayout.countChipText(for: count) == expected)
  }

  @Test("앨범에서 한 번에 최대 30장까지 고를 수 있다")
  func maxSelectionCount() {
    #expect(ChatPhotoLayout.maxSelectionCount == 30)
  }
}
