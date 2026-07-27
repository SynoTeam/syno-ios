//
//  ContactsView.swift
//  Syno
//
//  Created by 이승진 on 7/14/26.
//

import SwiftUI

struct ContactsView: View {
  @State private var viewModel: ContactsViewModel
  @State private var isFavoriteCollapsed = false
  @State private var isAllCollapsed = true
  @State private var toast: Toast?
  
  private let noteRepository: any NoteRepository
  private let noteImageAnalyzer: any NoteImageAnalyzing
  private let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  private let labelTranslator: any LabelTranslating
  
  init(
    userProfile: UserProfile? = nil,
    contactRepository: any ContactRepository,
    noteRepository: any NoteRepository,
    noteImageAnalyzer: any NoteImageAnalyzing,
    noteImageAnalysisRepository: any NoteImageAnalysisRepository,
    labelTranslator: any LabelTranslating
  ) {
    let myProfileId = userProfile?.id ?? UUID()
    self.noteRepository = noteRepository
    self.noteImageAnalyzer = noteImageAnalyzer
    self.noteImageAnalysisRepository = noteImageAnalysisRepository
    self.labelTranslator = labelTranslator
    _viewModel = State(
      initialValue: ContactsViewModel(
        repository: contactRepository,
        myProfileId: myProfileId,
        myProfileName: userProfile?.displayName
      )
    )
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        header
        
        if let myContact = viewModel.myContact {
          NavigationLink {
            MyPageView(
              contact: myContact,
              noteRepository: noteRepository,
              noteImageAnalyzer: noteImageAnalyzer,
              noteImageAnalysisRepository: noteImageAnalysisRepository,
              labelTranslator: labelTranslator,
              onSave: viewModel.saveMyContact
            )
          } label: {
            ContactsRowView(
              name: myContact.name,
              group: "My Profile",
              profileImageData: myContact.profileImageData,
              style: .me
            )
          }
          .buttonStyle(.plain)
        }
        
        if !viewModel.favoriteContacts.isEmpty {
          ContactsSectionView(
            title: "Favorite",
            count: viewModel.favoriteContacts.count,
            contacts: viewModel.favoriteContacts,
            noteRepository: noteRepository,
            noteImageAnalyzer: noteImageAnalyzer,
            noteImageAnalysisRepository: noteImageAnalysisRepository,
            labelTranslator: labelTranslator,
            isCollapsed: $isFavoriteCollapsed,
            onToggleFavorite: toggleFavorite,
            onDelete: deleteContact
          )
        }
        
        ContactsSectionView(
          title: "All",
          count: viewModel.regularContactCount,
          contacts: viewModel.regularContacts,
          noteRepository: noteRepository,
          noteImageAnalyzer: noteImageAnalyzer,
          noteImageAnalysisRepository: noteImageAnalysisRepository,
          labelTranslator: labelTranslator,
          isCollapsed: $isAllCollapsed,
          onToggleFavorite: toggleFavorite,
          onDelete: deleteContact
        )
        
        if viewModel.regularContacts.isEmpty {
          emptyState
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 20)
    }
    .background(Color.gray50)
    .onAppear {
      viewModel.loadContacts()
      isAllCollapsed = viewModel.regularContacts.isEmpty
    }
    .onChange(of: viewModel.persistenceError) { _, errorMessage in
      guard let errorMessage else {
        return
      }
      toast = Toast(
        message: errorMessage,
        style: .failure
      )
      viewModel.clearPersistenceError()
    }
    .toast(item: $toast)
  }
  
  private var header: some View {
    HStack {
      Text("Contacts")
        .typeStyle(.header)
        .foregroundStyle(.gray950)
      
      Spacer()
      
      NavigationLink {
        AddContactView { contact in
          viewModel.addContact(contact)
          isAllCollapsed = false
        }
      } label: {
        Image(systemName: "plus")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(.gray700)
          .frame(width: 44, height: 44)
          .background(.white)
          .clipShape(Circle())
      }
      .accessibilityLabel("Add Contact")
    }
  }
  
  private var emptyState: some View {
    VStack(spacing: 28) {
      Image(.logo)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 148, height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 20))
      
      Text("환영합니다!\n연락처를 추가해보세요.")
        .typeStyle(.headline)
        .foregroundStyle(.gray500)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 116)
  }
  
  private func deleteContact(id: Contact.ID) {
    viewModel.deleteContact(id: id)
    isAllCollapsed = viewModel.regularContacts.isEmpty
  }
  
  private func toggleFavorite(id: Contact.ID) {
    guard let isFavorite = viewModel.toggleFavorite(id: id) else {
      return
    }
    
    toast = Toast(
      message: isFavorite
      ? "즐겨찾기에 추가되었습니다"
      : "즐겨찾기 해제되었습니다",
      style: .success,
      icon: isFavorite ? "star.fill" : "star.slash.fill",
      action: Toast.Action(title: "되돌리기") {
        viewModel.setFavorite(
          id: id,
          isFavorite: !isFavorite
        )
      }
    )
  }
}

#Preview {
  NavigationStack {
    ContactsView(
      contactRepository: PreviewRepositories.contact,
      noteRepository: PreviewRepositories.note,
      noteImageAnalyzer: PreviewRepositories.noteImageAnalyzer,
      noteImageAnalysisRepository: PreviewRepositories.noteImageAnalysis,
      labelTranslator: PreviewRepositories.labelTranslator
    )
  }
}
