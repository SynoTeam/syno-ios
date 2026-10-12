import ImageIO
import UIKit

/// 전송할 사진을 미리 줄여 둔 결과입니다. 확인 화면에는 썸네일만 쓰고, 전송에는 줄여 둔 JPEG 데이터를 씁니다.
struct PreparedPhoto: @unchecked Sendable {
  let imageData: Data
  let thumbnail: UIImage
}

/// 큰 사진을 메모리에 원본 크기로 펼치지 않고 ImageIO로 바로 줄여서 전송용 데이터와 썸네일을 만듭니다.
enum PhotoPreparer {
  /// 저장하는 사진의 긴 변 최대 픽셀입니다.
  static let maxDimension: CGFloat = 1600
  /// 확인 화면에 쓰는 썸네일의 긴 변 최대 픽셀입니다.
  static let thumbnailDimension: CGFloat = 600

  /// 원본 데이터를 줄여 전송용 JPEG와 썸네일을 만듭니다. 읽을 수 없는 사진이면 nil입니다.
  /// 무거운 작업이라 메인 스레드가 아닌 곳에서 호출해야 합니다.
  nonisolated static func prepare(_ rawData: Data) -> PreparedPhoto? {
    guard
      let source = CGImageSourceCreateWithData(rawData as CFData, nil),
      let full = downsample(source, maxPixel: maxDimension),
      let jpeg = UIImage(cgImage: full).jpegData(compressionQuality: 0.8),
      let thumbnail = downsample(source, maxPixel: thumbnailDimension)
    else {
      return nil
    }
    return PreparedPhoto(imageData: jpeg, thumbnail: UIImage(cgImage: thumbnail))
  }

  /// 긴 변이 `maxPixel`을 넘지 않게 줄입니다. 원본이 더 작으면 키우지 않고, 회전 정보는 반영합니다.
  private nonisolated static func downsample(_ source: CGImageSource, maxPixel: CGFloat) -> CGImage? {
    let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    let width = (properties?[kCGImagePropertyPixelWidth] as? CGFloat) ?? maxPixel
    let height = (properties?[kCGImagePropertyPixelHeight] as? CGFloat) ?? maxPixel
    let target = min(maxPixel, max(width, height))

    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceThumbnailMaxPixelSize: target,
    ]
    return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
  }
}
