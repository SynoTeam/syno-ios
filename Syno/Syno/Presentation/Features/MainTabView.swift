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

  init(userProfile: UserProfile? = nil) {
    self.userProfile = userProfile
  }
  
  var body: some View {
    TabView(selection: $selectedTab) {
      Tab(AppTab.contacts.title, systemImage: AppTab.contacts.systemImage, value: .contacts) {
        NavigationStack {
          ContactsView(userProfile: userProfile)
        }
      }
      
      Tab(AppTab.notes.title, systemImage: AppTab.notes.systemImage, value: .notes) {
        NavigationStack {
          NotesView()
        }
      }
      
      Tab(AppTab.search.title, systemImage: AppTab.search.systemImage, value: .search, role: .search) {
        NavigationStack {
          SearchView()
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
  MainTabView()
}
