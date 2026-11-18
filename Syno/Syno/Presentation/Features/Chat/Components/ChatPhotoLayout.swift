import CoreGraphics

/// 채팅 사진 업로드와 단일 사진 말풍선의 표시 규칙입니다 (#138).
enum ChatPhotoLayout {
  /// 앨범에서 한 번에 고를 수 있는 사진 최대 개수입니다. 사진은 한 장씩 줄여 저장하고,
  /// 묶음 말풍선은 4장 이후를 "+N"으로 보여주므로 장수가 늘어도 말풍선 크기는 같습니다.
  static let maxSelectionCount = 30

  /// 단일 사진 말풍선의 최대 크기와, 짧은 변의 최소 길이입니다.
  private static let maxWidth: CGFloat = 220
  private static let maxHeight: CGFloat = 300
  private static let minSide: CGFloat = 120

  /// 단일 사진 말풍선 크기입니다. 최대 크기 안에서 원본 비율을 유지하고(작은 사진은 키워 맞춤),
  /// 파노라마처럼 한쪽이 너무 짧아지면 최소 길이로 늘린 뒤 넘치는 부분은 가운데 기준으로 잘라 보여줍니다.
  nonisolated static func singlePhotoSize(for imageSize: CGSize) -> CGSize {
    guard imageSize.width > 0, imageSize.height > 0 else {
      return CGSize(width: maxWidth, height: maxWidth)
    }
    let scale = min(maxWidth / imageSize.width, maxHeight / imageSize.height)
    let width = max(minSide, imageSize.width * scale)
    let height = max(minSide, imageSize.height * scale)
    return CGSize(width: width.rounded(), height: height.rounded())
  }

  /// 업로드 확인 시트에서 사진 아래에 보여줄 장수입니다. 한 장일 때는 보여주지 않습니다.
  nonisolated static func countChipText(for count: Int) -> String? {
    count > 1 ? "\(count)장" : nil
  }
}
