//
//  OnboardingBasicInfoViewModel.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import Foundation
import Observation

/// 온보딩 기본 정보 입력 화면의 입력 상태를 관리하는 ViewModel입니다.
@Observable
final class OnboardingBasicInfoViewModel {
  /// 사용자가 입력한 성입니다.
  var familyName = ""

  /// 사용자가 입력한 이름입니다.
  var givenName = ""

  /// 성 또는 이름 중 하나 이상 입력됐을 때 확인할 수 있는지 여부입니다.
  var canSubmit: Bool {
    !displayName.isEmpty
  }

  /// 성과 이름을 합친 사용자 표시 이름입니다.
  var displayName: String {
    "\(trimmed(familyName))\(trimmed(givenName))"
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// 현재 입력값을 SwiftData에 저장할 `UserProfile`로 변환합니다.
  func makeUserProfile() -> UserProfile {
    UserProfile(
      familyName: trimmed(familyName),
      givenName: trimmed(givenName)
    )
  }

  private func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
