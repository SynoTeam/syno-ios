//
//  SearchView.swift
//  Syno
//
//  Created by 이승진 on 7/14/26.
//

import SwiftData
import SwiftUI

struct SearchView: View {
  @State private var viewModel: SearchViewModel
  @FocusState private var isSearchFocused: Bool
  private let noteRepository: any NoteRepository

  init(
    modelContext: ModelContext,
    noteRepository: any NoteRepository,
    searchIndex: any SearchIndexing
  ) {
    self.noteRepository = noteRepository
    _viewModel = State(
      initialValue: SearchViewModel(
        modelContext: modelContext,
        searchIndex: searchIndex
      )
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      searchBar

      if viewModel.hasQuery {
        categoryPicker
      }

      content
    }
    .background(Color.gray50)
    .navigationBarHidden(true)
    .onDisappear(perform: viewModel.cancelSearch)
  }

  private var searchBar: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.gray400)

      TextField("연락처와 메모 검색", text: queryBinding)
        .typeStyle(.body)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .focused($isSearchFocused)
        .submitLabel(.search)
        .onSubmit(viewModel.commitCurrentQuery)

      if viewModel.hasQuery {
        Button {
          viewModel.clearQuery()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.gray400)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("검색어 지우기")
      }
    }
    .padding(.horizontal, 14)
    .frame(height: 48)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding(.horizontal, 16)
    .padding(.top, 12)
    .padding(.bottom, 10)
  }

  private var queryBinding: Binding<String> {
    Binding(
      get: { viewModel.query },
      set: { viewModel.updateQuery($0) }
    )
  }

  private var categoryPicker: some View {
    HStack(spacing: 8) {
      ForEach(SearchCategory.allCases) { category in
        Button {
          viewModel.selectedCategory = category
        } label: {
          Text(category.title)
            .typeStyle(.subheadline)
            .foregroundStyle(viewModel.selectedCategory == category ? .gray25 : .gray500)
            .padding(.horizontal, 16)
            .frame(height: 34)
            .background(viewModel.selectedCategory == category ? .gray800 : .white)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
      }

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 10)
  }

  @ViewBuilder
  private var content: some View {
    if !viewModel.hasQuery {
      RecentSearchesView(
        searches: viewModel.recentSearches,
        onSelect: {
          viewModel.selectRecentSearch($0)
          isSearchFocused = false
        },
        onDelete: viewModel.removeRecentSearch,
        onClear: viewModel.clearRecentSearches
      )
    } else if viewModel.isSearching {
      Spacer()
      ProgressView()
        .tint(.violet500)
      Spacer()
    } else if viewModel.filteredResults.isEmpty {
      SearchEmptyStateView(category: viewModel.selectedCategory)
    } else {
      resultsList
    }
  }

  private var resultsList: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(viewModel.filteredResults) { result in
          NavigationLink {
            destination(for: result)
          } label: {
            SearchResultRow(result: result)
          }
          .buttonStyle(.plain)
          .simultaneousGesture(
            TapGesture().onEnded {
              viewModel.commitCurrentQuery()
            }
          )
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 6)
      .padding(.bottom, 120)
    }
    .scrollDismissesKeyboard(.interactively)
  }

  @ViewBuilder
  private func destination(for result: SearchResult) -> some View {
    switch result {
    case .contact(let contact, _):
      ContactDetailView(contact: contact, noteRepository: noteRepository)
    case .note(_, let contact):
      ChatView(contact: contact, repository: noteRepository)
    }
  }
}

#Preview {
  let container = try! ModelContainer(
    for: StoredContact.self,
    StoredNote.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )

  NavigationStack {
    SearchView(
      modelContext: container.mainContext,
      noteRepository: SwiftDataNoteRepository(modelContext: container.mainContext),
      searchIndex: PreviewRepositories.searchIndex
    )
  }
}
