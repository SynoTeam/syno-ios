//
//  UserProfile.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import Foundation
import SwiftData

/// 온보딩에서 저장하는 사용자 기본 프로필 정보입니다.
@Model
final class UserProfile {
  /// 사용자 프로필의 고유 식별자입니다.
  var id: UUID

  /// 사용자의 성입니다.
  var familyName: String

  /// 사용자의 이름입니다.
  var givenName: String

  /// 프로필이 생성된 시각입니다.
  var createdAt: Date

  init(
    id: UUID = UUID(),
    familyName: String,
    givenName: String,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.familyName = familyName
    self.givenName = givenName
    self.createdAt = createdAt
  }
}

extension UserProfile {
  /// 성과 이름을 합친 사용자 표시 이름입니다.
  var displayName: String {
    let name = "\(familyName.trimmingCharacters(in: .whitespacesAndNewlines))\(givenName.trimmingCharacters(in: .whitespacesAndNewlines))"
    return name.isEmpty ? "내 프로필" : name
  }
}
