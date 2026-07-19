//
//  RootView.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftData
import SwiftUI

/// 저장된 사용자 프로필 존재 여부에 따라 온보딩 또는 메인 탭으로 분기하는 root view입니다.
struct RootView: View {
  @Query(sort: \UserProfile.createdAt) private var userProfiles: [UserProfile]

  var body: some View {
    if let userProfile = userProfiles.first {
      MainTabView(userProfile: userProfile)
    } else {
      NavigationStack {
        OnboardingStartView()
      }
    }
  }
}

#Preview {
  RootView()
}
