/// 사진 미리보기에서 무엇을 저장했는지입니다 (#140).
enum PhotoSaveScope {
  /// 혼자 보낸 사진 한 장
  case single
  /// 묶음 사진에서 "선택 사진만"
  case selected
  /// 묶음 사진에서 "전체 사진"
  case all
}

/// 사진 미리보기에서 사진 앱으로 저장한 결과 안내 규칙입니다 (#140).
enum PhotoSaveFeedback {
  /// 저장 결과 안내입니다. 하나라도 실패하면 범위와 관계없이 실패한 장수를 알려 다시 시도할 수 있게 합니다.
  nonisolated static func result(
    scope: PhotoSaveScope,
    savedCount: Int,
    failedCount: Int
  ) -> (message: String, isSuccess: Bool) {
    if savedCount == 0 {
      return ("사진을 저장하지 못했습니다", false)
    }
    if failedCount > 0 {
      return ("사진 \(failedCount)장을 저장하지 못했습니다", false)
    }
    switch scope {
    case .single:
      return ("사진이 저장되었습니다", true)
    case .selected:
      return ("선택 사진만 다운로드되었습니다", true)
    case .all:
      return ("전체 사진 다운로드되었습니다", true)
    }
  }
}
