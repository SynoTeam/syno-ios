//
//  MainTabView.swift
//  Syno
//
//  Created by 이승진 on 7/14/26.
//

import SwiftUI

struct MainTabView: View {
  @State private var selectedTab: AppTab = .contacts
  let userProfile: UserProfile?
  private let container: AppContainer

  init(userProfile: UserProfile? = nil, container: AppContainer) {
    self.userProfile = userProfile
    self.container = container
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab(AppTab.contacts.title, systemImage: AppTab.contacts.systemImage, value: .contacts) {
        NavigationStack {
          ContactsView(
            userProfile: userProfile,
            contactRepository: container.contactRepository,
            noteRepository: container.noteRepository,
            noteImageAnalyzer: container.noteImageAnalyzer,
            noteImageAnalysisRepository: container.noteImageAnalysisRepository,
            linkPreviewFetcher: container.linkPreviewFetcher,
            noteLinkPreviewRepository: container.noteLinkPreviewRepository,
            labelTranslator: container.labelTranslator,
            noteVoiceTranscriber: container.noteVoiceTranscriber,
            noteVoiceTranscriptRepository: container.noteVoiceTranscriptRepository,
            accountResetService: container.accountResetService
          )
        }
        // 탭바 선택색(보라)은 TabView의 tint를 쓰고, 화면 안의 기본 강조색은 검은색으로 덮어쓴다.
        .tint(.gray950)
      }
      
      Tab(AppTab.notes.title, systemImage: AppTab.notes.systemImage, value: .notes) {
        NavigationStack {
          NotesView(
            noteRepository: container.noteRepository,
            contactRepository: container.contactRepository,
            noteImageAnalyzer: container.noteImageAnalyzer,
            noteImageAnalysisRepository: container.noteImageAnalysisRepository,
            linkPreviewFetcher: container.linkPreviewFetcher,
            noteLinkPreviewRepository: container.noteLinkPreviewRepository,
            labelTranslator: container.labelTranslator,
            noteVoiceTranscriber: container.noteVoiceTranscriber,
            noteVoiceTranscriptRepository: container.noteVoiceTranscriptRepository
          )
        }
        .tint(.gray950)
      }
      
      Tab(AppTab.search.title, systemImage: AppTab.search.systemImage, value: .search, role: .search) {
        NavigationStack {
          SearchView(
            noteRepository: container.noteRepository,
            contactRepository: container.contactRepository,
            searchIndex: container.searchIndex,
            noteImageAnalyzer: container.noteImageAnalyzer,
            noteImageAnalysisRepository: container.noteImageAnalysisRepository,
            linkPreviewFetcher: container.linkPreviewFetcher,
            noteLinkPreviewRepository: container.noteLinkPreviewRepository,
            labelTranslator: container.labelTranslator,
            noteVoiceTranscriber: container.noteVoiceTranscriber,
            noteVoiceTranscriptRepository: container.noteVoiceTranscriptRepository
          )
        }
        .tint(.gray950)
      }
    }
    .tint(.violet500)
  }
}

private enum AppTab: Hashable {
  case contacts
  case notes
  case search
  
  var title: String {
    switch self {
    case .contacts:
      "Contacts"
    case .notes:
      "Notes"
    case .search:
      "Search"
    }
  }
  
  var systemImage: String {
    switch self {
    case .contacts:
      "person.crop.circle"
    case .notes:
      "note.text"
    case .search:
      "magnifyingglass"
    }
  }
}

#Preview {
  MainTabView(container: PreviewRepositories.appContainer)
    .previewModelContainer()
}
