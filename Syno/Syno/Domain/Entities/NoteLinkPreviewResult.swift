import Foundation

/// 노트 본문 URL에서 추출한 Open Graph 미리보기 정보입니다.
struct NoteLinkPreviewResult: Equatable, Sendable {
  let title: String
  let imageURL: URL?
  let siteURL: URL
}
