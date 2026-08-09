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
  let noteImageAnalyzer: any NoteImageAnalyzing
  let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  let linkPreviewFetcher: any NoteLinkPreviewFetching
  let noteLinkPreviewRepository: any NoteLinkPreviewRepository
  let labelTranslator: any LabelTranslating
  let noteVoiceTranscriber: any NoteVoiceTranscribing
  let noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository
  let accountResetService: AccountResetService

  var body: some View {
    if let userProfile = userProfiles.first {
      MainTabView(
        userProfile: userProfile,
        contactRepository: contactRepository,
        noteRepository: noteRepository,
        searchIndex: searchIndex,
        noteImageAnalyzer: noteImageAnalyzer,
        noteImageAnalysisRepository: noteImageAnalysisRepository,
        linkPreviewFetcher: linkPreviewFetcher,
        noteLinkPreviewRepository: noteLinkPreviewRepository,
        labelTranslator: labelTranslator,
        noteVoiceTranscriber: noteVoiceTranscriber,
        noteVoiceTranscriptRepository: noteVoiceTranscriptRepository,
        accountResetService: accountResetService
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
    searchIndex: PreviewRepositories.searchIndex,
    noteImageAnalyzer: PreviewRepositories.noteImageAnalyzer,
    noteImageAnalysisRepository: PreviewRepositories.noteImageAnalysis,
    linkPreviewFetcher: PreviewRepositories.linkPreviewFetcher,
    noteLinkPreviewRepository: PreviewRepositories.noteLinkPreview,
    labelTranslator: PreviewRepositories.labelTranslator,
    noteVoiceTranscriber: PreviewRepositories.noteVoiceTranscriber,
    noteVoiceTranscriptRepository: PreviewRepositories.noteVoiceTranscript,
    accountResetService: PreviewRepositories.accountReset
  )
}
