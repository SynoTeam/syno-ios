//
//  MainTabView.swift
//  Syno
//
//  Created by 이승진 on 7/14/26.
//

import SwiftData
import SwiftUI

struct MainTabView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var selectedTab: AppTab = .contacts
  let userProfile: UserProfile?
  private let contactRepository: any ContactRepository
  private let noteRepository: any NoteRepository
  private let searchIndex: any SearchIndexing
  private let noteImageAnalyzer: any NoteImageAnalyzing
  private let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  private let linkPreviewFetcher: any NoteLinkPreviewFetching
  private let noteLinkPreviewRepository: any NoteLinkPreviewRepository
  private let labelTranslator: any LabelTranslating
  private let noteVoiceTranscriber: any NoteVoiceTranscribing
  private let noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository
  private let accountResetService: AccountResetService

  init(
    userProfile: UserProfile? = nil,
    contactRepository: any ContactRepository,
    noteRepository: any NoteRepository,
    searchIndex: any SearchIndexing,
    noteImageAnalyzer: any NoteImageAnalyzing,
    noteImageAnalysisRepository: any NoteImageAnalysisRepository,
    linkPreviewFetcher: any NoteLinkPreviewFetching,
    noteLinkPreviewRepository: any NoteLinkPreviewRepository,
    labelTranslator: any LabelTranslating,
    noteVoiceTranscriber: any NoteVoiceTranscribing,
    noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository,
    accountResetService: AccountResetService
  ) {
    self.userProfile = userProfile
    self.contactRepository = contactRepository
    self.noteRepository = noteRepository
    self.searchIndex = searchIndex
    self.noteImageAnalyzer = noteImageAnalyzer
    self.noteImageAnalysisRepository = noteImageAnalysisRepository
    self.linkPreviewFetcher = linkPreviewFetcher
    self.noteLinkPreviewRepository = noteLinkPreviewRepository
    self.labelTranslator = labelTranslator
    self.noteVoiceTranscriber = noteVoiceTranscriber
    self.noteVoiceTranscriptRepository = noteVoiceTranscriptRepository
    self.accountResetService = accountResetService
  }
  
  var body: some View {
    TabView(selection: $selectedTab) {
      Tab(AppTab.contacts.title, systemImage: AppTab.contacts.systemImage, value: .contacts) {
        NavigationStack {
          ContactsView(
            userProfile: userProfile,
            contactRepository: contactRepository,
            noteRepository: noteRepository,
            noteImageAnalyzer: noteImageAnalyzer,
            noteImageAnalysisRepository: noteImageAnalysisRepository,
            linkPreviewFetcher: linkPreviewFetcher,
            noteLinkPreviewRepository: noteLinkPreviewRepository,
            labelTranslator: labelTranslator,
            noteVoiceTranscriber: noteVoiceTranscriber,
            noteVoiceTranscriptRepository: noteVoiceTranscriptRepository,
            accountResetService: accountResetService
          )
        }
      }
      
      Tab(AppTab.notes.title, systemImage: AppTab.notes.systemImage, value: .notes) {
        NavigationStack {
          NotesView(
            noteRepository: noteRepository,
            contactRepository: contactRepository,
            noteImageAnalyzer: noteImageAnalyzer,
            noteImageAnalysisRepository: noteImageAnalysisRepository,
            linkPreviewFetcher: linkPreviewFetcher,
            noteLinkPreviewRepository: noteLinkPreviewRepository,
            labelTranslator: labelTranslator,
            noteVoiceTranscriber: noteVoiceTranscriber,
            noteVoiceTranscriptRepository: noteVoiceTranscriptRepository
          )
        }
      }
      
      Tab(AppTab.search.title, systemImage: AppTab.search.systemImage, value: .search, role: .search) {
        NavigationStack {
          SearchView(
            modelContext: modelContext,
            noteRepository: noteRepository,
            searchIndex: searchIndex,
            noteImageAnalyzer: noteImageAnalyzer,
            noteImageAnalysisRepository: noteImageAnalysisRepository,
            linkPreviewFetcher: linkPreviewFetcher,
            noteLinkPreviewRepository: noteLinkPreviewRepository,
            labelTranslator: labelTranslator,
            noteVoiceTranscriber: noteVoiceTranscriber,
            noteVoiceTranscriptRepository: noteVoiceTranscriptRepository
          )
        }
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
  MainTabView(
    contactRepository: PreviewRepositories.contact,
    noteRepository: PreviewRepositories.note,
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
