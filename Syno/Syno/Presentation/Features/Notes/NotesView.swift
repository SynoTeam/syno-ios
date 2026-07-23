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

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        filterChips

        if viewModel.isEmpty {
          NotesEmptyStateView()
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
    .onChange(of: storedNotes.map(\.note)) {
      loadStoredNotes()
    }
    .onChange(of: storedContacts.map { "\($0.id.uuidString):\($0.isFavorite)" }) {
      loadStoredNotes()
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
          ChatView(contact: note.contact)
        } label: {
          NoteRowView(note: note)
        }
        .buttonStyle(.plain)
      }
    }
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
}

#Preview {
  NotesView()
    .modelContainer(for: [StoredNote.self, StoredContact.self], inMemory: true)
}
