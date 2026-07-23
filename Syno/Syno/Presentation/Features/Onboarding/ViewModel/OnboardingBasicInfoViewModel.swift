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
  private(set) var persistenceError: String?

  private let repository: any UserProfileRepository

  init(repository: any UserProfileRepository) {
    self.repository = repository
  }

  /// 성 또는 이름 중 하나 이상 입력됐을 때 확인할 수 있는지 여부입니다.
  var canSubmit: Bool {
    !displayName.isEmpty
  }

  /// 성과 이름을 합친 사용자 표시 이름입니다.
  var displayName: String {
    "\(trimmed(familyName))\(trimmed(givenName))"
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func saveUserProfile() {
    do {
      try repository.save(
        familyName: trimmed(familyName),
        givenName: trimmed(givenName)
      )
      persistenceError = nil
    } catch {
      persistenceError = "프로필을 저장하지 못했습니다. 다시 시도해주세요."
    }
  }

  func clearPersistenceError() {
    persistenceError = nil
  }

  private func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
