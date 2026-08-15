import SwiftUI
import UIKit

/// 채팅에서 주고받은 텍스트/사진/음성메모/파일/링크를 한눈에 모아보는 아카이브 화면입니다.
///
/// 카테고리별로 최근 항목 3~6개만 미리보기로 보여주고, "더 보기"를 누르면
/// ``ArchiveCategoryListView``에서 해당 카테고리의 전체 목록을 봅니다.
struct ArchiveView: View {
  let viewModel: ChatViewModel

  @State private var isSearching = false
  @State private var searchText = ""
  @FocusState private var isSearchFocused: Bool
  @State private var selectedCategory: ArchiveCategory?

  private let rowPreviewCount = 3
  private let mediaPreviewCount = 6

  var body: some View {
    VStack(spacing: 0) {
      if isSearching {
        searchBar
      }

      ScrollView {
        if hasAnyResults {
          VStack(spacing: 16) {
            sectionCard(icon: .message, title: "텍스트", category: .text, isEmpty: textNotes.isEmpty) {
              VStack(alignment: .leading, spacing: 16) {
                ForEach(textNotes.prefix(rowPreviewCount)) { note in
                  textRow(note)
                }
              }
            }

            sectionCard(icon: .image, title: "사진", category: .photos, isEmpty: photoNotes.isEmpty, showsDivider: false) {
              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                  ForEach(photoNotes.prefix(mediaPreviewCount)) { note in
                    photoThumbnail(note)
                  }
                }
              }
            }

            sectionCard(icon: .play, title: "음성 메모", category: .voiceMemos, isEmpty: voiceMemoNotes.isEmpty) {
              VStack(alignment: .leading, spacing: 16) {
                ForEach(voiceMemoNotes.prefix(rowPreviewCount)) { note in
                  voiceMemoRow(note)
                }
              }
            }

            sectionCard(icon: .document, title: "파일", category: .files, isEmpty: fileNotes.isEmpty) {
              VStack(alignment: .leading, spacing: 16) {
                ForEach(fileNotes.prefix(rowPreviewCount)) { note in
                  fileRow(note)
                }
              }
            }

            sectionCard(icon: .link, title: "링크", category: .links, isEmpty: linkNotes.isEmpty, showsDivider: false) {
              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                  ForEach(linkNotes.prefix(mediaPreviewCount)) { note in
                    if let preview = viewModel.linkPreviews[note.id] {
                      LinkPreviewCard(preview: preview)
                        .frame(width: 160)
                    }
                  }
                }
              }
            }
          }
          .padding(16)
        } else {
          archiveEmptyState(
            image: .emptyArchive,
            message: trimmedSearchText.isEmpty ? "아직 저장된 항목이 없습니다" : "검색 결과가 없습니다"
          )
        }
      }
    }
    .background(Color.gray50)
    .navigationTitle("아카이브")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          toggleSearch()
        } label: {
          Image(systemName: isSearching ? "xmark" : "magnifyingglass")
            .foregroundStyle(.gray950)
        }
        .accessibilityLabel(isSearching ? "검색 닫기" : "검색")
      }
    }
    .navigationDestination(item: $selectedCategory) { category in
      ArchiveCategoryListView(viewModel: viewModel, startingCategory: category)
    }
  }

  // MARK: - Sections

  @ViewBuilder
  private func sectionCard<Content: View>(
    icon: ImageResource,
    title: String,
    category: ArchiveCategory,
    isEmpty: Bool,
    showsDivider: Bool = true,
    @ViewBuilder content: () -> Content
  ) -> some View {
    if !isEmpty {
      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 6) {
          Image(icon)
            .resizable()
            .renderingMode(.template)
            .frame(width: 14, height: 14)
            .foregroundStyle(.gray400)

          Text(title)
            .typeStyle(.footnote)
            .foregroundStyle(.gray400)
        }

        content()

        if showsDivider {
          Divider()
        }

        Button {
          selectedCategory = category
        } label: {
          Text("더 보기")
            .typeStyle(.subheadline)
            .foregroundStyle(.gray500)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
      }
      .padding(16)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 16))
    }
  }

  private func textRow(_ note: Note) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(.logo)
          .profileImage(data: note.profileImageData, size: 32)

        Text(note.contactName)
          .typeStyle(.subheadlineEmphasized)
          .foregroundStyle(.gray950)

        Spacer()

        Text(note.clockTimeText)
          .typeStyle(.caption1)
          .foregroundStyle(.gray400)
      }

      Text(note.content)
        .typeStyle(.footnote)
        .foregroundStyle(.gray600)
        .lineLimit(1)
        .truncationMode(.tail)
    }
  }

  private func photoThumbnail(_ note: Note) -> some View {
    Group {
      if let imageData = note.imageData, let uiImage = UIImage(data: imageData) {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
      } else {
        Color.gray100
      }
    }
    .frame(width: 96, height: 84)
    .clipped()
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private func voiceMemoRow(_ note: Note) -> some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 4) {
        Text(note.content)
          .typeStyle(.subheadlineEmphasized)
          .foregroundStyle(.gray950)
          .lineLimit(1)

        Text(ArchiveFormatters.dayText(for: note.createdAt))
          .typeStyle(.caption1)
          .foregroundStyle(.gray400)
      }

      Spacer()

      Text(ArchiveFormatters.durationText(note.voiceMemoDuration))
        .typeStyle(.caption1)
        .foregroundStyle(.gray400)
    }
  }

  private func fileRow(_ note: Note) -> some View {
    HStack(spacing: 12) {
      Image(.messageFile)
        .resizable()
        .frame(width: 32, height: 28)

      VStack(alignment: .leading, spacing: 4) {
        Text(note.fileName ?? note.content)
          .typeStyle(.subheadlineEmphasized)
          .foregroundStyle(.gray950)
          .lineLimit(1)

        Text(ByteCountFormatter.string(fromByteCount: Int64(note.fileSize ?? 0), countStyle: .file))
          .typeStyle(.caption1)
          .foregroundStyle(.gray400)
      }

      Spacer()
    }
  }

  // MARK: - Filtering

  private var trimmedSearchText: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var hasAnyResults: Bool {
    !textNotes.isEmpty || !photoNotes.isEmpty || !voiceMemoNotes.isEmpty || !fileNotes.isEmpty || !linkNotes.isEmpty
  }

  private var textNotes: [Note] {
    viewModel.messages
      .filter { $0.imageData == nil && $0.voiceMemoData == nil && $0.fileName == nil }
      .filter { trimmedSearchText.isEmpty || viewModel.matches($0, searchText: trimmedSearchText) }
      .sorted { $0.createdAt > $1.createdAt }
  }

  private var photoNotes: [Note] {
    viewModel.messages
      .filter { $0.imageData != nil }
      .filter { trimmedSearchText.isEmpty || viewModel.matches($0, searchText: trimmedSearchText) }
      .sorted { $0.createdAt > $1.createdAt }
  }

  private var voiceMemoNotes: [Note] {
    viewModel.messages
      .filter { $0.voiceMemoData != nil }
      .filter { note in
        guard !trimmedSearchText.isEmpty else { return true }
        let transcript: String
        if case let .transcribed(result) = viewModel.voiceMemoStates[note.id] { transcript = result.text } else { transcript = "" }
        return note.content.localizedStandardContains(trimmedSearchText) || transcript.localizedStandardContains(trimmedSearchText)
      }
      .sorted { $0.createdAt > $1.createdAt }
  }

  private var fileNotes: [Note] {
    viewModel.messages
      .filter { $0.fileName != nil }
      .filter { note in
        trimmedSearchText.isEmpty || (note.fileName ?? note.content).localizedStandardContains(trimmedSearchText)
      }
      .sorted { $0.createdAt > $1.createdAt }
  }

  private var linkNotes: [Note] {
    viewModel.messages
      .filter { viewModel.linkPreviews[$0.id] != nil }
      .filter { note in
        guard !trimmedSearchText.isEmpty else { return true }
        guard let preview = viewModel.linkPreviews[note.id] else { return false }
        return preview.title.localizedStandardContains(trimmedSearchText)
          || (preview.siteURL.host ?? "").localizedStandardContains(trimmedSearchText)
      }
      .sorted { $0.createdAt > $1.createdAt }
  }

  private var searchBar: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.gray400)

      TextField("검색", text: $searchText)
        .typeStyle(.body)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .focused($isSearchFocused)

      if !searchText.isEmpty {
        Button {
          searchText = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.gray400)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 14)
    .frame(height: 44)
    .background(.gray100)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding(.horizontal, 16)
    .padding(.top, 10)
    .padding(.bottom, 4)
  }

  private func toggleSearch() {
    isSearching.toggle()
    if isSearching {
      isSearchFocused = true
    } else {
      searchText = ""
      isSearchFocused = false
    }
  }
}

/// 아카이브 미리보기 카드의 "더 보기"로 이동할 수 있는 카테고리입니다.
enum ArchiveCategory: CaseIterable, Hashable {
  case text
  case photos
  case voiceMemos
  case files
  case links

  var title: String {
    switch self {
    case .text: "텍스트"
    case .photos: "사진"
    case .voiceMemos: "음성"
    case .files: "파일"
    case .links: "링크"
    }
  }
}

/// 아카이브 카테고리 미리보기와 전체 목록이 함께 쓰는 날짜/재생시간 포맷터입니다.
enum ArchiveFormatters {
  static func dayText(for date: Date) -> String {
    let isCurrentYear = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
    return (isCurrentYear ? monthDayFormatter : yearMonthDayFormatter).string(from: date)
  }

  static func durationText(_ duration: TimeInterval?) -> String {
    String(format: "%d:%02d", Int(duration ?? 0) / 60, Int(duration ?? 0) % 60)
  }

  private static let monthDayFormatter = makeFormatter("M월 d일 (E)")
  private static let yearMonthDayFormatter = makeFormatter("yyyy년 M월 d일 (E)")

  private static func makeFormatter(_ dateFormat: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = dateFormat
    return formatter
  }
}

func archiveEmptyState(image: ImageResource, message: String) -> some View {
  VStack(spacing: 16) {
    Image(image)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: 88, height: 88)

    Text(message)
      .typeStyle(.subheadline)
      .foregroundStyle(.gray400)
  }
  .frame(maxWidth: .infinity)
  .padding(.top, 80)
}
