//
//  GroupOptions.swift
//  Syno
//
//  Created by Codex on 7/28/26.
//

import Foundation

/// 연락처 그룹 목록을 병합하고 중복을 제거하는 순수 로직입니다.
enum GroupOptions {
  /// 저장된 연락처, 현재 폼의 임시 그룹을 병합해 정렬된 목록으로 반환합니다.
  static func merged(
    existingGroups: [String],
    draftGroup: String
  ) -> [String] {
    let groups = existingGroups + [draftGroup]
    var uniqueGroups: [String] = []

    for group in groups {
      let trimmedGroup = group.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmedGroup.isEmpty else {
        continue
      }

      guard matchingGroup(for: trimmedGroup, in: uniqueGroups) == nil else {
        continue
      }

      uniqueGroups.append(trimmedGroup)
    }

    return uniqueGroups.sorted { lhs, rhs in
      let lhsRank = scriptRank(for: lhs)
      let rhsRank = scriptRank(for: rhs)

      guard lhsRank == rhsRank else {
        return lhsRank < rhsRank
      }

      return lhs.localizedStandardCompare(rhs) == .orderedAscending
    }
  }

  /// 한글을 영문(알파벳)보다 먼저 정렬하기 위한 순위입니다. 기기 로케일에 따라
  /// 스크립트 간 정렬 순서가 달라지는 걸 막기 위해 스크립트별로 먼저 구간을 나눕니다.
  private static func scriptRank(for group: String) -> Int {
    guard let firstScalar = group.unicodeScalars.first else {
      return 0
    }

    return firstScalar.isASCII ? 1 : 0
  }

  /// 대소문자를 구분하지 않고 동일한 기존 그룹을 반환합니다.
  static func matchingGroup(for group: String, in groups: [String]) -> String? {
    let trimmedGroup = group.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedGroup.isEmpty else {
      return nil
    }

    return groups.first {
      $0.compare(trimmedGroup, options: .caseInsensitive) == .orderedSame
    }
  }
}
