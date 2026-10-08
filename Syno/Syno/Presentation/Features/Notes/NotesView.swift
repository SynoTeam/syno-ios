//
//  NotesView.swift
//  Syno
//
//  Created by 이승진 on 7/14/26.
//

import SwiftData
import SwiftUI

struct NotesView: View {
  @Environment(\.analytics) private var analytics
  @Query(sort: \StoredNote.createdAt, order: .reverse) private var storedNotes: [StoredNote]
  @Query private var storedContacts: [StoredContact]
  @Query(sort: \StoredGroup.sortIndex) private var storedGroups: [StoredGroup]
  @State private var viewModel = NotesViewModel()
  @State private var isShowingAddContact = false
  @State private var toast: Toast?
  @State private var isShowingGroupManagement = false
  @State private var isShowingDeletion = false
  @State private var selectedNote: Note?
  @State private var openSwipe: OpenNoteSwipe?
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  let noteRepository: any NoteRepository
  let contactRepository: any ContactRepository
  let noteImageAnalyzer: any NoteImageAnalyzing
  let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  let linkPreviewFetcher: any NoteLinkPreviewFetching
  let noteLinkPreviewRepository: any NoteLinkPreviewRepository
  let labelTranslator: any LabelTranslating
  let noteVoiceTranscriber: any NoteVoiceTranscribing
  let noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        header

        VStack(alignment: .leading, spacing: 24) {
          filterChips

          if viewModel.isEmpty {
            emptyState
          } else {
            notesList
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 120)
    }
    .background(Color.gray50)
    .toast(item: $toast)
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .onAppear(perform: loadStoredNotes)
    .onChange(of: storedNoteChangeTokens) {
      loadStoredNotes()
    }
    .onChange(of: storedContacts.map {
      // 이름과 프로필 사진이 바뀌어도 노트 목록이 다시 계산되도록 변경 토큰에 포함한다.
      "\($0.id.uuidString):\($0.isFavorite):\($0.isPinned):\($0.group):\($0.name):\($0.profileImageData?.count ?? 0)"
    }) {
      loadStoredNotes()
    }
    .onChange(of: storedGroups.map { "\($0.persistentModelID):\($0.name):\($0.sortIndex)" }) {
      loadStoredNotes()
    }
    .navigationDestination(isPresented: $isShowingAddContact) {
      AddContactView { contact in
        saveContact(contact)
      }
    }
    .navigationDestination(item: $selectedNote) { note in
      ChatView(
        contact: note.contact,
        repository: noteRepository,
        imageAnalyzer: noteImageAnalyzer,
        imageAnalysisRepository: noteImageAnalysisRepository,
        linkPreviewFetcher: linkPreviewFetcher,
        linkPreviewRepository: noteLinkPreviewRepository,
        labelTranslator: labelTranslator,
        voiceTranscriber: noteVoiceTranscriber,
        voiceTranscriptRepository: noteVoiceTranscriptRepository,
        analytics: analytics
      )
    }
    .onChange(of: viewModel.filteredNotes.map(\.id)) { _, visibleIDs in
      // 필터나 삭제로 사라진 행의 열림 상태가 남지 않도록 정리한다.
      if let openSwipe, !visibleIDs.contains(openSwipe.id) {
        self.openSwipe = nil
      }
    }
    .navigationDestination(isPresented: $isShowingDeletion) {
      NotesDeletionView(
        viewModel: viewModel,
        onDelete: { notes in deleteNotes(notes) },
        onDeleted: { _ in
          isShowingDeletion = false
          showNotesDeletedToast()
        }
      )
    }
    .sheet(isPresented: $isShowingGroupManagement) {
      GroupManagementSheet()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
  }

  private var storedNoteChangeTokens: [StoredNoteChangeToken] {
    storedNotes.map { storedNote in
      StoredNoteChangeToken(
        id: storedNote.id,
        contactId: storedNote.contactId,
        content: storedNote.content,
        createdAt: storedNote.createdAt
      )
    }
  }

  private var header: some View {
    TabRootHeader(title: "Notes") {
      Menu {
        Picker("정렬 기준", selection: $viewModel.sortOrder) {
          ForEach(NoteSortOrder.allCases) { sortOrder in
            Label(sortOrder.title, systemImage: sortOrder.systemImage)
              .tag(sortOrder)
          }
        }

        Button {
          isShowingGroupManagement = true
        } label: {
          Label("그룹 편집", systemImage: "folder")
        }

        Button {
          isShowingDeletion = true
        } label: {
          Label("선택 삭제", systemImage: "trash")
        }
      } label: {
        HeaderCircleIcon(.moreHorizontal)
      }
      .tint(.gray700)
      .accessibilityLabel("노트 정렬")
    }
  }

  private var filterChips: some View {
    NoteFilterChipBar(
      filters: viewModel.availableFilters,
      selectedFilter: viewModel.selectedFilter
    ) { filter in
      viewModel.selectedFilter = filter
    }
  }

  private var notesList: some View {
    LazyVStack(spacing: 8) {
      ForEach(viewModel.filteredNotes) { note in
        NotePinSwipeRow(
          id: note.id,
          openSwipe: $openSwipe,
          isPinned: note.isPinned,
          onTogglePin: { togglePin(for: note) },
          onDelete: { requestDelete(note) }
        ) {
          NoteRowView(note: note)
            .contentShape(Rectangle())
            // NavigationLink는 가로로 민 뒤 손을 뗄 때 탭으로 인식되어 이동해버리므로 TapGesture를 쓴다.
            .onTapGesture {
              guard openSwipe == nil else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
                  openSwipe = nil
                }
                return
              }
              selectedNote = note
            }
            .accessibilityAddTraits(.isButton)
        }
      }
    }
  }

  private var emptyState: some View {
    NotesEmptyStateView(
      state: storedContacts.isEmpty ? .noContacts : .noNotes,
      onAddContact: storedContacts.isEmpty ? { isShowingAddContact = true } : nil
    )
  }

  private func loadStoredNotes() {
    let favoriteContactIds = Set(
      storedContacts
        .filter(\.isFavorite)
        .map(\.id)
    )
    let pinnedContactIds = Set(
      storedContacts
        .filter(\.isPinned)
        .map(\.id)
    )
    let groupNames = storedGroups.map(\.name)
    let groupNamesByContactID = Dictionary(
      uniqueKeysWithValues: storedContacts.map { contact in
        let canonicalName = groupNames.first {
          $0.compare(contact.group, options: .caseInsensitive) == .orderedSame
        } ?? contact.group
        return (contact.id, canonicalName)
      }
    )

    viewModel.replaceNotes(
      resolvedNotes(),
      favoriteContactIds: favoriteContactIds,
      pinnedContactIds: pinnedContactIds,
      groupNames: groupNames,
      groupNamesByContactID: groupNamesByContactID
    )
  }

  /// 노트에 복사돼 저장된 이름·사진 대신, 연결된 연락처의 최신 값을 표시용으로 덮어씁니다.
  /// 연결된 연락처가 없는 노트는 저장된 값을 그대로 사용합니다.
  private func resolvedNotes() -> [Note] {
    let contactsByID = Dictionary(
      storedContacts.map { ($0.id, $0) },
      uniquingKeysWith: { first, _ in first }
    )

    return storedNotes.map { storedNote in
      var note = storedNote.note
      if
        let contactId = note.contactId,
        let contact = contactsByID[contactId]
      {
        note.contactName = contact.name
        note.profileImageData = contact.profileImageData
      }
      return note
    }
  }

  private func saveContact(_ contact: Contact) -> Bool {
    do {
      try contactRepository.save(contact)
      return true
    } catch {
      return false
    }
  }

  /// 노트 삭제 확인 모달을 띄웁니다. 확인하면 해당 연락처의 노트와 파일이 모두 삭제됩니다.
  private func requestDelete(_ note: Note) {
    confirmationAlert = DestructiveConfirmationAlert(
      title: "해당 노트를\n영구적으로 삭제하겠습니까?",
      message: "연락처 내 모든 노트와 파일이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.",
      acknowledgementText: nil
    ) {
      delete(note)
    }
  }

  private func delete(_ note: Note) {
    guard deleteNotes([note]) else {
      toast = Toast(
        message: "노트를 삭제하지 못했습니다.",
        style: .failure
      )
      return
    }
    showNotesDeletedToast()
  }

  /// 선택한 노트의 연락처 데이터를 삭제합니다. 연락처가 연결되지 않은 오래된 노트는 해당 노트만 삭제합니다.
  private func deleteNotes(_ notes: [Note]) -> Bool {
    do {
      for note in notes {
        if let contactId = note.contactId {
          try noteRepository.deleteAll(contactId: contactId)
        } else {
          try noteRepository.delete(id: note.id)
        }
      }
      return true
    } catch {
      return false
    }
  }

  private func showNotesDeletedToast() {
    toast = Toast(
      message: "노트가 삭제되었습니다.",
      style: .success,
      icon: "trash.fill"
    )
  }

  private func togglePin(for note: Note) {
    setPin(!note.isPinned, for: note, showsSuccessToast: true)
  }

  private func setPin(
    _ isPinned: Bool,
    for note: Note,
    showsSuccessToast: Bool
  ) {
    guard
      let contactId = note.contactId,
      let storedContact = storedContacts.first(where: { $0.id == contactId })
    else {
      return
    }

    var updatedContact = storedContact.contact
    updatedContact.isPinned = isPinned

    do {
      try contactRepository.save(updatedContact)

      guard showsSuccessToast else {
        return
      }

      toast = Toast(
        message: isPinned ? "핀 추가되었습니다" : "핀 해제되었습니다",
        style: .success,
        icon: isPinned ? "pin.fill" : "pin.slash.fill",
        action: Toast.Action(title: "되돌리기") {
          setPin(!isPinned, for: note, showsSuccessToast: false)
        }
      )
    } catch {
      toast = Toast(
        message: isPinned ? "핀 추가 실패했습니다" : "핀 해제 실패했습니다",
        style: .failure
      )
    }
  }
}

private struct StoredNoteChangeToken: Equatable {
  let id: UUID
  let contactId: UUID?
  let content: String
  let createdAt: Date
}

#Preview {
  NotesView(
    noteRepository: PreviewRepositories.note,
    contactRepository: PreviewRepositories.contact,
    noteImageAnalyzer: PreviewRepositories.noteImageAnalyzer,
    noteImageAnalysisRepository: PreviewRepositories.noteImageAnalysis,
    linkPreviewFetcher: PreviewRepositories.linkPreviewFetcher,
    noteLinkPreviewRepository: PreviewRepositories.noteLinkPreview,
    labelTranslator: PreviewRepositories.labelTranslator,
    noteVoiceTranscriber: PreviewRepositories.noteVoiceTranscriber,
    noteVoiceTranscriptRepository: PreviewRepositories.noteVoiceTranscript
  )
    .modelContainer(for: [StoredNote.self, StoredContact.self, StoredGroup.self], inMemory: true)
}
