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
      Tab(value: AppTab.contacts) {
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
      } label: {
        AppTab.contacts.label
      }
      
      Tab(value: AppTab.notes) {
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
      } label: {
        AppTab.notes.label
      }
      
      Tab(value: AppTab.search, role: .search) {
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
      } label: {
        AppTab.search.label
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
  
  var icon: ImageResource {
    switch self {
    case .contacts:
      .person
    case .notes:
      .card
    case .search:
      .search
    }
  }

  var label: some View {
    Label {
      Text(title)
    } icon: {
      Image(icon)
        .renderingMode(.template)
    }
  }
}

#Preview {
  MainTabView(container: PreviewRepositories.appContainer)
    .previewModelContainer()
}
