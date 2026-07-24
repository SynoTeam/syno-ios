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
  let contactRepository: any ContactRepository
  let noteRepository: any NoteRepository
  let userProfileRepository: any UserProfileRepository
  let searchIndex: any SearchIndexing

  var body: some View {
    if let userProfile = userProfiles.first {
      MainTabView(
        userProfile: userProfile,
        contactRepository: contactRepository,
        noteRepository: noteRepository,
        searchIndex: searchIndex
      )
    } else {
      NavigationStack {
        OnboardingStartView(userProfileRepository: userProfileRepository)
      }
    }
  }
}

#Preview {
  RootView(
    contactRepository: PreviewRepositories.contact,
    noteRepository: PreviewRepositories.note,
    userProfileRepository: PreviewRepositories.userProfile,
    searchIndex: PreviewRepositories.searchIndex
  )
}
