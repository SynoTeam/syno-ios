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
  private let noteImageAnalyzer: any NoteImageAnalyzing
  private let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  private let linkPreviewFetcher: any NoteLinkPreviewFetching
  private let noteLinkPreviewRepository: any NoteLinkPreviewRepository
  private let labelTranslator: any LabelTranslating
  private let noteVoiceTranscriber: any NoteVoiceTranscribing
  private let noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository

  init(
    modelContext: ModelContext,
    noteRepository: any NoteRepository,
    searchIndex: any SearchIndexing,
    noteImageAnalyzer: any NoteImageAnalyzing,
    noteImageAnalysisRepository: any NoteImageAnalysisRepository,
    linkPreviewFetcher: any NoteLinkPreviewFetching,
    noteLinkPreviewRepository: any NoteLinkPreviewRepository,
    labelTranslator: any LabelTranslating,
    noteVoiceTranscriber: any NoteVoiceTranscribing,
    noteVoiceTranscriptRepository: any NoteVoiceTranscriptRepository
  ) {
    self.noteRepository = noteRepository
    self.noteImageAnalyzer = noteImageAnalyzer
    self.noteImageAnalysisRepository = noteImageAnalysisRepository
    self.linkPreviewFetcher = linkPreviewFetcher
    self.noteLinkPreviewRepository = noteLinkPreviewRepository
    self.labelTranslator = labelTranslator
    self.noteVoiceTranscriber = noteVoiceTranscriber
    self.noteVoiceTranscriptRepository = noteVoiceTranscriptRepository
    _viewModel = State(
      initialValue: SearchViewModel(
        modelContext: modelContext,
        searchIndex: searchIndex,
        noteImageAnalysisRepository: noteImageAnalysisRepository,
        noteLinkPreviewRepository: noteLinkPreviewRepository,
        noteVoiceTranscriptRepository: noteVoiceTranscriptRepository,
        labelTranslator: labelTranslator
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

      TextField("텍스트, 사진, 링크 검색", text: queryBinding)
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
    HStack(spacing: 0) {
      ForEach(SearchCategory.allCases) { category in
        Button {
          viewModel.selectedCategory = category
        } label: {
          VStack(spacing: 8) {
            Text(category.title)
              .typeStyle(viewModel.selectedCategory == category ? .calloutEmphasized : .callout)
              .foregroundStyle(viewModel.selectedCategory == category ? .violet600 : .gray950)

            Rectangle()
              .fill(viewModel.selectedCategory == category ? Color.violet400 : Color.clear)
              .frame(height: 2)
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.top, 4)
    .overlay(alignment: .bottom) {
      Divider()
    }
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

  private let photoColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)
  private let linkColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

  private var resultsList: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 20) {
        if viewModel.selectedCategory == .all {
          ForEach([SearchCategory.text, .photo, .link, .voice], id: \.self) { category in
            let categoryResults = viewModel.results(for: category)
            if !categoryResults.isEmpty {
              sectionCard(
                category: category,
                results: Array(categoryResults.prefix(3)),
                showMore: categoryResults.count > 3
              )
            }
          }
        } else {
          VStack(alignment: .leading, spacing: 12) {
            resultsGrid(for: viewModel.selectedCategory, results: viewModel.filteredResults)
          }
          .padding(16)
          .background(.white)
          .clipShape(RoundedRectangle(cornerRadius: 20))
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 6)
      .padding(.bottom, 120)
    }
    .scrollDismissesKeyboard(.interactively)
  }

  private func sectionCard(category: SearchCategory, results: [SearchResult], showMore: Bool) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 6) {
        Image(systemName: sectionIconName(for: category))
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.gray300)
        Text(category.title).typeStyle(.subheadlineEmphasized).foregroundStyle(.gray500)
      }
      resultsGrid(for: category, results: results)

      if showMore {
        VStack(spacing: 12) {
          Divider()
            .background(Color.gray100)
          
          Button("더 보기") { viewModel.selectedCategory = category }
            .typeStyle(.calloutEmphasized)
            .foregroundStyle(.gray500)
            .frame(maxWidth: .infinity)
        }
      }
    }
    .padding(16)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }

  @ViewBuilder
  private func resultsGrid(for category: SearchCategory, results: [SearchResult]) -> some View {
    switch category {
    case .text:
      VStack(spacing: 8) {
        ForEach(results) { resultLink($0) }
      }
    case .photo:
      LazyVGrid(columns: photoColumns, spacing: 4) {
        ForEach(results) { resultLink($0) }
      }
    case .link:
      LazyVGrid(columns: linkColumns, spacing: 12) {
        ForEach(results) { resultLink($0) }
      }
    case .voice:
      VStack(spacing: 8) {
        ForEach(results) { resultLink($0) }
      }
    case .all:
      EmptyView()
    }
  }

  private func sectionIconName(for category: SearchCategory) -> String {
    switch category {
    case .all: "magnifyingglass"
    case .text: "message.fill"
    case .photo: "photo"
    case .link: "link"
    case .voice: "waveform"
    }
  }

  private func resultLink(_ result: SearchResult) -> some View {
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

  @ViewBuilder
  private func destination(for result: SearchResult) -> some View {
    switch result {
    case let .text(_, contact), let .photo(_, contact), let .link(_, contact, _), let .voice(_, contact, _):
      ChatView(
        contact: contact,
        repository: noteRepository,
        imageAnalyzer: noteImageAnalyzer,
        imageAnalysisRepository: noteImageAnalysisRepository,
        linkPreviewFetcher: linkPreviewFetcher,
        linkPreviewRepository: noteLinkPreviewRepository,
        labelTranslator: labelTranslator,
        voiceTranscriber: noteVoiceTranscriber,
        voiceTranscriptRepository: noteVoiceTranscriptRepository
      )
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
      searchIndex: PreviewRepositories.searchIndex,
      noteImageAnalyzer: PreviewRepositories.noteImageAnalyzer,
      noteImageAnalysisRepository: PreviewRepositories.noteImageAnalysis,
      linkPreviewFetcher: PreviewRepositories.linkPreviewFetcher,
      noteLinkPreviewRepository: PreviewRepositories.noteLinkPreview,
      labelTranslator: PreviewRepositories.labelTranslator,
      noteVoiceTranscriber: PreviewRepositories.noteVoiceTranscriber,
      noteVoiceTranscriptRepository: PreviewRepositories.noteVoiceTranscript
    )
  }
}
