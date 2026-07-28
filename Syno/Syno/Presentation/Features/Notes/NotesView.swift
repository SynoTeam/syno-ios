//
//  NotesView.swift
//  Syno
//
//  Created by 이승진 on 7/14/26.
//

import SwiftData
import SwiftUI

struct NotesView: View {
  @Query(sort: \StoredNote.createdAt, order: .reverse) private var storedNotes: [StoredNote]
  @Query private var storedContacts: [StoredContact]
  @State private var viewModel = NotesViewModel()
  @State private var isShowingAddContact = false
  let noteRepository: any NoteRepository
  let contactRepository: any ContactRepository
  let noteImageAnalyzer: any NoteImageAnalyzing
  let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  let labelTranslator: any LabelTranslating

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        filterChips

        if viewModel.isEmpty {
          emptyState
        } else {
          notesList
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 120)
    }
    .background(Color.gray50)
    .onAppear(perform: loadStoredNotes)
    .onChange(of: storedNoteChangeTokens) {
      loadStoredNotes()
    }
    .onChange(of: storedContacts.map { "\($0.id.uuidString):\($0.isFavorite)" }) {
      loadStoredNotes()
    }
    .navigationDestination(isPresented: $isShowingAddContact) {
      AddContactView(existingGroups: existingGroups) { contact in
        saveContact(contact)
      }
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
    HStack {
      Text("Notes")
        .typeStyle(.header)
        .foregroundStyle(.gray950)

      Spacer()

      Menu {
        Picker("정렬 기준", selection: $viewModel.sortOrder) {
          ForEach(NoteSortOrder.allCases) { sortOrder in
            Label(sortOrder.title, systemImage: sortOrder.systemImage)
              .tag(sortOrder)
          }
        }
      } label: {
        Image(systemName: "ellipsis")
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(.gray700)
          .frame(width: 44, height: 44)
          .background(.white)
          .clipShape(Circle())
      }
      .accessibilityLabel("노트 정렬")
    }
  }

  private var filterChips: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(viewModel.availableFilters, id: \.self) { filter in
          NoteFilterChip(
            title: filter.title,
            isSelected: viewModel.selectedFilter == filter
          ) {
            viewModel.selectedFilter = filter
          }
        }
      }
    }
    .scrollClipDisabled()
  }

  private var notesList: some View {
    LazyVStack(spacing: 14) {
      ForEach(viewModel.filteredNotes) { note in
        NavigationLink {
          ChatView(
            contact: note.contact,
            repository: noteRepository,
            imageAnalyzer: noteImageAnalyzer,
            imageAnalysisRepository: noteImageAnalysisRepository,
            labelTranslator: labelTranslator
          )
        } label: {
          NoteRowView(note: note)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var emptyState: some View {
    NotesEmptyStateView(
      state: storedContacts.isEmpty ? .noContacts : .noNotes,
      onAddContact: storedContacts.isEmpty ? { isShowingAddContact = true } : nil
    )
  }

  private var existingGroups: [String] {
    GroupOptions.merged(
      existingGroups: storedContacts.map(\.group),
      draftGroup: ""
    )
  }

  private func loadStoredNotes() {
    let favoriteContactIds = Set(
      storedContacts
        .filter(\.isFavorite)
        .map(\.id)
    )
    viewModel.replaceNotes(
      storedNotes.map(\.note),
      favoriteContactIds: favoriteContactIds
    )
  }

  private func saveContact(_ contact: Contact) -> Bool {
    do {
      try contactRepository.save(contact)
      return true
    } catch {
      return false
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
    labelTranslator: PreviewRepositories.labelTranslator
  )
    .modelContainer(for: [StoredNote.self, StoredContact.self], inMemory: true)
}
