import SwiftUI
import UIKit

/// 채팅에서 주고받은 텍스트/사진/음성메모/파일/링크를 한눈에 모아보는 아카이브 화면입니다.
///
/// 카테고리별로 최근 항목 3~6개만 미리보기로 보여주고, "더 보기"를 누르면
/// ``ArchiveCategoryListView``에서 해당 카테고리의 전체 목록을 봅니다.
struct ArchiveView: View {
  let viewModel: ChatViewModel

  @Environment(\.analytics) private var analytics
  @State private var isSearching = false
  @State private var searchText = ""
  @State private var selectedCategory: ArchiveCategory?

  private let rowPreviewCount = 3
  private let mediaPreviewCount = 6

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        if hasAnyResults {
          VStack(spacing: 16) {
            sectionCard(icon: .messageFilled, title: "텍스트", category: .text, isEmpty: textNotes.isEmpty) {
              VStack(alignment: .leading, spacing: 20) {
                ForEach(textNotes.prefix(rowPreviewCount)) { note in
                  textRow(note)
                }
              }
            }

            sectionCard(icon: .image, title: "사진", category: .photos, isEmpty: photoNotes.isEmpty) {
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

            sectionCard(icon: .link, title: "링크", category: .links, isEmpty: linkNotes.isEmpty) {
              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                  ForEach(linkNotes.prefix(mediaPreviewCount)) { note in
                    if let preview = viewModel.linkPreviews[note.id] {
                      // 시안: 첫 화면 링크 카드는 144×124 (#142)
                      LinkPreviewCard(preview: preview, height: 124, background: .gray50)
                        .frame(width: 144)
                    }
                  }
                }
              }
            }
          }
          .padding(16)
        } else {
          archiveEmptyState(
            image: trimmedSearchText.isEmpty ? .emptyData : .emptyDataSearch,
            message: trimmedSearchText.isEmpty ? "아직 저장된 항목이 없습니다" : "검색 결과가 없습니다"
          )
        }
      }
    }
    .background(Color.gray50)
    .navigationTitle("아카이브")
    .navigationBarTitleDisplayMode(.inline)
    .synoBackButton()
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          isSearching = true
        } label: {
          Image(.search)
            .resizable()
            .renderingMode(.template)
            .frame(width: 20, height: 20)
            .foregroundStyle(.gray950)
        }
        .accessibilityLabel("검색")
      }
    }
    .searchable(text: $searchText, isPresented: $isSearching, prompt: "검색")
    .onChange(of: isSearching) { _, isSearching in
      if !isSearching {
        searchText = ""
      }
    }
    .navigationDestination(item: $selectedCategory) { category in
      ArchiveCategoryListView(viewModel: viewModel, startingCategory: category)
    }
    .trackScreen("archive")
  }

  // MARK: - Sections

  @ViewBuilder
  private func sectionCard<Content: View>(
    icon: ImageResource,
    title: String,
    category: ArchiveCategory,
    isEmpty: Bool,
    @ViewBuilder content: () -> Content
  ) -> some View {
    if !isEmpty {
      VStack(alignment: .leading, spacing: 16) {
        // 시안: 연한 아이콘과 굵은 제목 (#142)
        HStack(spacing: 6) {
          Image(icon)
            .resizable()
            .renderingMode(.template)
            .frame(width: 16, height: 16)
            .foregroundStyle(.gray300)

          Text(title)
            .typeStyle(.subheadlineEmphasized)
            .foregroundStyle(.gray500)
        }

        content()

        // 모든 섹션에서 "더 보기" 위에 같은 구분선을 둔다 (#142).
        Rectangle()
          .fill(.gray100)
          .frame(height: 1)

        Button {
          selectedCategory = category
          analytics.track(
            AnalyticsEvent.archiveCategoryOpened,
            properties: [AnalyticsEvent.Property.category: String(describing: category)]
          )
        } label: {
          Text("더 보기")
            .typeStyle(.calloutEmphasized)
            .foregroundStyle(.gray500)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("archive.more.\(String(describing: category))")
      }
      .padding(16)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 16))
    }
  }

  /// 노트 목록과 같은 행 내용을 쓰고, 이름은 14자에서 말줄임하며 검색어를 강조한다 (#142).
  private func textRow(_ note: Note) -> some View {
    var displayNote = note
    displayNote.contactName = ArchiveFormatters.contactNameText(note.contactName)
    return NoteRowContent(note: displayNote, highlightQuery: trimmedSearchText.isEmpty ? nil : trimmedSearchText)
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
    // 사진 비율과 관계없이 정사각형으로 가운데를 잘라 보여준다 (#142).
    .frame(width: 100, height: 100)
    .clipShape(RoundedRectangle(cornerRadius: 14.3))
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

  /// 텍스트 목록의 이름입니다. 14자를 넘으면 앞 14자 뒤에 "…"를 붙입니다 (#142).
  /// 화면에 보이는 글자 단위로 세므로 이모지나 결합 문자가 중간에서 잘리지 않습니다.
  static func contactNameText(_ name: String) -> String {
    let limit = 14
    guard name.count > limit else {
      return name
    }
    return String(name.prefix(limit)) + "…"
  }

  static func durationText(_ duration: TimeInterval?) -> String {
    String(format: "%d:%02d", Int(duration ?? 0) / 60, Int(duration ?? 0) % 60)
  }

  /// 음성 목록과 재생 카드의 시간입니다. 시안처럼 분:초를 두 자리씩 씁니다(예: 00:23) (#144).
  static func playbackTimeText(_ seconds: TimeInterval?) -> String {
    guard let seconds, seconds.isFinite, seconds > 0 else { return "00:00" }
    let total = Int(seconds)
    return String(format: "%02d:%02d", total / 60, total % 60)
  }

  /// 재생 카드 진행 막대의 채움 비율(0...1)입니다. 길이를 모르면 0입니다 (#144).
  static func playbackProgress(elapsed: TimeInterval, duration: TimeInterval) -> Double {
    guard duration > 0, elapsed.isFinite else { return 0 }
    return min(max(elapsed / duration, 0), 1)
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

/// 아카이브의 빈 화면입니다. 다른 빈 화면들과 같이 그림과 문구를 가운데 정렬하고,
/// 스크롤 영역 높이를 채워 화면 세로 가운데에 둡니다.
func archiveEmptyState(image: ImageResource, message: String) -> some View {
  VStack(alignment: .center, spacing: 16) {
    Image(image)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: 88, height: 88)

    Text(message)
      .typeStyle(.headlineRegular)
      .foregroundStyle(.gray500)
      .multilineTextAlignment(.center)
  }
  .frame(maxWidth: .infinity, alignment: .center)
  .containerRelativeFrame(.vertical, alignment: .center)
  .emptyStatePosition()
}
