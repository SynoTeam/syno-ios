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

  init(
    userProfile: UserProfile? = nil,
    contactRepository: any ContactRepository,
    noteRepository: any NoteRepository,
    searchIndex: any SearchIndexing
  ) {
    self.userProfile = userProfile
    self.contactRepository = contactRepository
    self.noteRepository = noteRepository
    self.searchIndex = searchIndex
  }
  
  var body: some View {
    TabView(selection: $selectedTab) {
      Tab(AppTab.contacts.title, systemImage: AppTab.contacts.systemImage, value: .contacts) {
        NavigationStack {
          ContactsView(
            userProfile: userProfile,
            contactRepository: contactRepository,
            noteRepository: noteRepository
          )
        }
      }
      
      Tab(AppTab.notes.title, systemImage: AppTab.notes.systemImage, value: .notes) {
        NavigationStack {
          NotesView(noteRepository: noteRepository)
        }
      }
      
      Tab(AppTab.search.title, systemImage: AppTab.search.systemImage, value: .search, role: .search) {
        NavigationStack {
          SearchView(
            modelContext: modelContext,
            noteRepository: noteRepository,
            searchIndex: searchIndex
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
    searchIndex: PreviewRepositories.searchIndex
  )
}
