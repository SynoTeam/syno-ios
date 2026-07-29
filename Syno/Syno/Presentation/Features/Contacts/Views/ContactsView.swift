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
  @State private var contactPendingDeletion: Contact?
  @State private var selectedContact: Contact?
  
  private let noteRepository: any NoteRepository
  private let noteImageAnalyzer: any NoteImageAnalyzing
  private let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  private let linkPreviewFetcher: any NoteLinkPreviewFetching
  private let noteLinkPreviewRepository: any NoteLinkPreviewRepository
  private let labelTranslator: any LabelTranslating
  private let accountResetService: AccountResetService
  
  init(
    userProfile: UserProfile? = nil,
    contactRepository: any ContactRepository,
    noteRepository: any NoteRepository,
    noteImageAnalyzer: any NoteImageAnalyzing,
    noteImageAnalysisRepository: any NoteImageAnalysisRepository,
    linkPreviewFetcher: any NoteLinkPreviewFetching,
    noteLinkPreviewRepository: any NoteLinkPreviewRepository,
    labelTranslator: any LabelTranslating,
    accountResetService: AccountResetService
  ) {
    let myProfileId = userProfile?.id ?? UUID()
    self.noteRepository = noteRepository
    self.noteImageAnalyzer = noteImageAnalyzer
    self.noteImageAnalysisRepository = noteImageAnalysisRepository
    self.linkPreviewFetcher = linkPreviewFetcher
    self.noteLinkPreviewRepository = noteLinkPreviewRepository
    self.labelTranslator = labelTranslator
    self.accountResetService = accountResetService
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
              linkPreviewFetcher: linkPreviewFetcher,
              noteLinkPreviewRepository: noteLinkPreviewRepository,
              labelTranslator: labelTranslator,
              existingGroups: viewModel.existingGroups,
              accountResetService: accountResetService,
              onSave: { contact in
                _ = viewModel.saveMyContact(contact)
              }
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
            onSelectContact: { selectedContact = $0 },
            isCollapsed: $isFavoriteCollapsed,
            onToggleFavorite: toggleFavorite,
            onDelete: requestDelete
          )
        }

        ContactsSectionView(
          title: "All",
          count: viewModel.regularContactCount,
          contacts: viewModel.regularContacts,
          onSelectContact: { selectedContact = $0 },
          isCollapsed: $isAllCollapsed,
          onToggleFavorite: toggleFavorite,
          onDelete: requestDelete
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
    .navigationDestination(item: $contactPendingDeletion) { contact in
      ContactsDeleteView(
        viewModel: viewModel,
        initiallySelectedContactID: contact.id,
        onDeleted: handleDeletedContacts
      )
    }
    .navigationDestination(item: $selectedContact) { contact in
      ContactDetailView(
        contact: contact,
        noteRepository: noteRepository,
        noteImageAnalyzer: noteImageAnalyzer,
        noteImageAnalysisRepository: noteImageAnalysisRepository,
        linkPreviewFetcher: linkPreviewFetcher,
        noteLinkPreviewRepository: noteLinkPreviewRepository,
        labelTranslator: labelTranslator,
        viewModel: viewModel,
        existingGroups: viewModel.existingGroups,
        onDeleted: {
          selectedContact = nil
          showContactDeletedToast()
        }
      )
    }
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
        AddContactView(existingGroups: viewModel.existingGroups) { contact in
          guard viewModel.addContact(contact) else {
            return false
          }
          isAllCollapsed = false
          return true
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
      Image(.emptyList)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 120, height: 120)
      
      Text("환영합니다!\n연락처를 추가해보세요.")
        .typeStyle(.headline)
        .foregroundStyle(.gray500)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 116)
  }
  
  private func requestDelete(contact: Contact) {
    contactPendingDeletion = contact
  }

  private func handleDeletedContacts(_ count: Int) {
    contactPendingDeletion = nil
    isAllCollapsed = viewModel.regularContacts.isEmpty
    toast = Toast(
      message: "연락처 \(count)건이 삭제되었습니다.",
      style: .success,
      icon: "trash.fill"
    )
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

  private func showContactDeletedToast() {
    isAllCollapsed = viewModel.regularContacts.isEmpty
    toast = Toast(
      message: "연락처가 삭제되었습니다",
      style: .success,
      icon: "trash.fill"
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
      linkPreviewFetcher: PreviewRepositories.linkPreviewFetcher,
      noteLinkPreviewRepository: PreviewRepositories.noteLinkPreview,
      labelTranslator: PreviewRepositories.labelTranslator,
      accountResetService: PreviewRepositories.accountReset
    )
  }
}
