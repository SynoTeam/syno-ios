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
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @Environment(\.analytics) private var analytics
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
      if viewModel.hasQuery {
        categoryPicker
      }

      content
    }
    // 내용이 없어도 화면 전체를 채워야 빈 곳을 탭해서 키보드를 내릴 수 있다.
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray50)
    // 검색창 밖의 빈 곳을 탭하면 키보드를 내린다.
    .dismissKeyboardOnTap($isSearchFocused)
    .navigationBarTitleDisplayMode(.inline)
    // 제목도 버튼도 없는 빈 바가 검색창 활성 여부에 따라 접히고 나타나며 내용을 밀지 않도록 숨긴다.
    .toolbar(.hidden, for: .navigationBar)
    .searchable(text: queryBinding, prompt: "텍스트, 사진, 링크 검색")
    .searchFocused($isSearchFocused)
    .task {
      // 검색 탭에 들어오면 바로 입력할 수 있도록 검색창에 포커스를 준다.
      // 결과 화면에서 돌아온 경우(검색어가 있는 경우)에는 키보드를 다시 띄우지 않는다.
      guard !viewModel.hasQuery else {
        return
      }
      try? await Task.sleep(for: .milliseconds(300))
      isSearchFocused = true
    }
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .onSubmit(of: .search, commitSearch)
    .onDisappear(perform: viewModel.cancelSearch)
    .trackScreen("search")
  }

  private var queryBinding: Binding<String> {
    Binding(
      get: { viewModel.query },
      set: { viewModel.updateQuery($0) }
    )
  }

  /// 최근 검색어 전체 삭제는 되돌릴 수 없어서 확인 모달을 한 번 거친다.
  private func requestClearRecentSearches() {
    isSearchFocused = false
    confirmationAlert = DestructiveConfirmationAlert(
      title: "최근 검색어를\n모두 삭제하겠습니까?",
      message: "삭제한 검색어는 복구할 수 없습니다.",
      acknowledgementText: nil
    ) {
      viewModel.clearRecentSearches()
    }
  }

  private func commitSearch() {
    Task {
      guard let result = await viewModel.commitCurrentQuery() else { return }
      analytics.track(
        AnalyticsEvent.searchPerformed,
        properties: [
          AnalyticsEvent.Property.category: result.category.rawValue,
          AnalyticsEvent.Property.hasResults: result.hasResults
        ]
      )
    }
  }

  private var categoryPicker: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 0) {
          ForEach(SearchCategory.allCases) { category in
            categoryTab(category)
              .id(category)
          }
        }
        // 앞뒤 8pt만 띄우고, 아래 회색 줄은 화면 전체 폭으로 둔다.
        .padding(.horizontal, 8)
      }
      .padding(.top, 16)
      .overlay(alignment: .bottom) {
        Divider()
      }
      .onChange(of: viewModel.selectedCategory) { _, category in
        // 선택한 탭이 가운데로 오도록 자동 스크롤한다.
        withAnimation(.easeInOut(duration: 0.25)) {
          proxy.scrollTo(category, anchor: .center)
        }
      }
    }
  }

  private func categoryTab(_ category: SearchCategory) -> some View {
    let isSelected = viewModel.selectedCategory == category

    return Button {
      viewModel.selectedCategory = category
    } label: {
      VStack(spacing: 0) {
        Text(category.title)
          .typeStyle(isSelected ? .calloutEmphasized : .callout)
          .foregroundStyle(isSelected ? .violet600 : .gray950)
          .frame(maxHeight: .infinity)

        Rectangle()
          .fill(isSelected ? Color.violet400 : Color.clear)
          .frame(height: 2)
      }
      // 탭 폭은 고정(음성메모만 더 넓게), 높이는 42, 탭끼리 간격은 0이다.
      .frame(width: category == .voice ? 90 : 65, height: 42)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var content: some View {
    if !viewModel.hasQuery {
      RecentSearchesView(
        searches: viewModel.recentSearches,
        onSelect: viewModel.selectRecentSearch,
        onDelete: viewModel.removeRecentSearch,
        onClear: requestClearRecentSearches
      )
    } else if viewModel.isSearching && viewModel.filteredResults.isEmpty {
      // 이미 보여줄 결과가 있으면 검색 중에도 그대로 두어, 입력할 때마다 목록이 스피너로 바뀌며 깜빡이지 않게 한다.
      Spacer()
      ProgressView()
        .tint(.violet500)
      Spacer()
    } else if viewModel.filteredResults.isEmpty {
      SearchEmptyStateView(category: viewModel.selectedCategory)
    } else {
      resultsList
        // 새 검색이 끝나기 전의 이전 결과를 눌러 엉뚱한 곳으로 이동하거나 새 검색어가 저장되지 않도록 막는다.
        .allowsHitTesting(!viewModel.isSearching)
    }
  }

  /// 사진은 100pt, 링크는 144pt 고정 크기 타일을 열 안에서 가운데 정렬해 고르게 배치한다.
  private let photoColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)
  private let linkColumns = [GridItem(.flexible(), spacing: 0), GridItem(.flexible(), spacing: 0)]

  private var resultsList: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 20) {
        if viewModel.selectedCategory == .all {
          ForEach([SearchCategory.text, .photo, .voice, .file, .link], id: \.self) { category in
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
          // 안쪽 행이 자기 여백을 이미 가지므로 카드 좌우 여백은 8만 둔다(행 폭 = 화면 - 16 - 16 - 16).
          .padding(.horizontal, 8)
          .padding(.vertical, 16)
          .background(.white)
          .clipShape(RoundedRectangle(cornerRadius: 20))
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 16)
      .padding(.bottom, 120)
    }
    .scrollDismissesKeyboard(.interactively)
    .scrollBounceBehavior(.basedOnSize)
  }

  private func sectionCard(category: SearchCategory, results: [SearchResult], showMore: Bool) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 6) {
        sectionIcon(for: category)
        Text(category.title).typeStyle(.subheadlineEmphasized).foregroundStyle(.gray500)
      }
      resultsGrid(for: category, results: results)
        // 헤더와 "더 보기"는 카드 여백(16)을 유지하고, 결과 행만 좌우 8로 넓힌다.
        .padding(.horizontal, -8)

      if showMore {
        VStack(spacing: 12) {
          // 시안의 구분선은 카드 안쪽 여백보다 바깥(좌우 8)까지 이어진다.
          Rectangle()
            .fill(.gray100)
            .frame(height: 1)
            .padding(.horizontal, -8)
          
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
      VStack(spacing: 0) {
        ForEach(results) { resultLink($0) }
      }
    case .photo:
      LazyVGrid(columns: photoColumns, spacing: 0) {
        ForEach(results) { resultLink($0) }
      }
    case .link:
      LazyVGrid(columns: linkColumns, spacing: 0) {
        ForEach(results) { resultLink($0) }
      }
    case .voice:
      VStack(spacing: 0) {
        ForEach(results) { resultLink($0) }
      }
    case .file:
      VStack(spacing: 0) {
        ForEach(results) { resultLink($0) }
      }
    case .all:
      EmptyView()
    }
  }

  /// 카테고리 카드 헤더 아이콘입니다. 에셋이 있는 카테고리는 에셋을 쓰고 음성메모만 SF Symbol을 씁니다.
  @ViewBuilder
  private func sectionIcon(for category: SearchCategory) -> some View {
    switch category {
    case .all:
      sectionAssetIcon(.search)
    case .text:
      sectionAssetIcon(.message)
    case .photo:
      sectionAssetIcon(.image)
    case .link:
      sectionAssetIcon(.link)
    case .file:
      sectionAssetIcon(.document)
    case .voice:
      Image(systemName: "waveform")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.gray300)
        .frame(width: 20, height: 20)
    }
  }

  private func sectionAssetIcon(_ resource: ImageResource) -> some View {
    Image(resource)
      .resizable()
      .renderingMode(.template)
      .foregroundStyle(.gray300)
      .frame(width: 20, height: 20)
  }

  private func resultLink(_ result: SearchResult) -> some View {
    NavigationLink {
      destination(for: result)
    } label: {
      SearchResultRow(result: result, highlightQuery: viewModel.query)
    }
    .buttonStyle(.plain)
    .simultaneousGesture(
      TapGesture().onEnded {
        viewModel.recordCurrentQuery()
      }
    )
  }

  @ViewBuilder
  private func destination(for result: SearchResult) -> some View {
    switch result {
    case let .text(_, contact), let .photo(_, contact), let .link(_, contact, _), let .voice(_, contact, _), let .file(_, contact):
      ChatView(
        contact: contact,
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
