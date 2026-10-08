import SwiftUI

extension Text {
  /// 검색어와 일치하는 부분(대소문자 무시, 모든 위치)에 배경색 하이라이트를 입힌 텍스트입니다.
  /// 검색어가 비어 있으면 일반 텍스트로 표시합니다.
  init(highlighting text: String, query: String?, color: Color = .violet200) {
    var attributed = AttributedString(text)
    let query = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    if !query.isEmpty {
      var searchRange = attributed.startIndex..<attributed.endIndex
      while let range = attributed[searchRange].range(of: query, options: .caseInsensitive) {
        attributed[range].backgroundColor = color
        searchRange = range.upperBound..<attributed.endIndex
      }
    }

    self.init(attributed)
  }
}
