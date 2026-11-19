import Testing
@testable import Syno

/// 사진 미리보기에서 사진 앱으로 저장한 결과 안내 규칙입니다 (#140).
@MainActor
struct PhotoSaveFeedbackTests {
  @Test("저장 범위와 결과에 따라 안내 문구와 성공 여부가 정해진다", arguments: [
    // 혼자 보낸 사진 저장 성공
    (PhotoSaveScope.single, 1, 0, "사진이 저장되었습니다", true),
    // 묶음에서 "선택 사진만"
    (.selected, 1, 0, "선택 사진만 다운로드되었습니다", true),
    // 묶음에서 "전체 사진"
    (.all, 5, 0, "전체 사진 다운로드되었습니다", true),
    // 일부 실패 → 범위와 관계없이 실패한 장수를 알린다
    (.all, 3, 2, "사진 2장을 저장하지 못했습니다", false),
    // 모두 실패
    (.single, 0, 1, "사진을 저장하지 못했습니다", false),
    (.selected, 0, 1, "사진을 저장하지 못했습니다", false),
    (.all, 0, 4, "사진을 저장하지 못했습니다", false),
  ] as [(PhotoSaveScope, Int, Int, String, Bool)])
  func resultMessage(scope: PhotoSaveScope, savedCount: Int, failedCount: Int, message: String, isSuccess: Bool) {
    let feedback = PhotoSaveFeedback.result(scope: scope, savedCount: savedCount, failedCount: failedCount)

    #expect(feedback.message == message)
    #expect(feedback.isSuccess == isSuccess)
  }
}
