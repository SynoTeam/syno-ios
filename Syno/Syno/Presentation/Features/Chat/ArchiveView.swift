import SwiftUI
import UIKit

/// 채팅에서 주고받은 사진/링크를 모아보는 아카이브 화면입니다.
struct ArchiveView: View {
  private enum Tab: CaseIterable {
    case photos
    case links
    case voiceMemos
    case files

    var title: String {
      switch self {
      case .photos: "사진"
      case .links: "링크"
      case .voiceMemos: "음성"
      case .files: "파일"
      }
    }
  }

  let viewModel: ChatViewModel

  @State private var selectedTab: Tab = .photos
  @State private var isSearching = false
  @State private var searchText = ""
  @FocusState private var isSearchFocused: Bool
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?
  @State private var toastedFailedFileDownloadIds: Set<Note.ID> = []

  private let photoColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)
  private let linkColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

  var body: some View {
    VStack(spacing: 0) {
      tabPicker

      if isSearching {
        searchBar
      }

      ScrollView {
        switch selectedTab {
        case .photos:
          photoGrid
        case .links:
          linkGrid
        case .voiceMemos:
          voiceMemoGrid
        case .files:
          fileList
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
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
    .onChange(of: viewModel.fileDownloadStates) { _, newStates in
      handleFileDownloadStateChange(newStates)
    }
  }

  private var tabPicker: some View {
    HStack(spacing: 0) {
      ForEach(Tab.allCases, id: \.self) { tab in
        Button {
          selectedTab = tab
        } label: {
          VStack(spacing: 8) {
            Text(tab.title)
              .typeStyle(.subheadline)
              .foregroundStyle(selectedTab == tab ? .gray950 : .gray400)

            Rectangle()
              .fill(selectedTab == tab ? Color.violet500 : Color.clear)
              .frame(height: 2)
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.top, 12)
    .overlay(alignment: .bottom) {
      Divider()
    }
  }

  private var trimmedSearchText: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var photoSections: [ChatViewModel.MessageDaySection] {
    let calendar = Calendar.current
    var photoNotes = viewModel.messages.filter { $0.imageData != nil }
    if !trimmedSearchText.isEmpty {
      photoNotes = photoNotes.filter { viewModel.matches($0, searchText: trimmedSearchText) }
    }
    let grouped = Dictionary(grouping: photoNotes) { calendar.startOfDay(for: $0.createdAt) }
    return grouped
      .map { date, notes in
        ChatViewModel.MessageDaySection(
          date: date,
          messages: notes.sorted { $0.createdAt < $1.createdAt }
        )
      }
      .sorted { $0.date < $1.date }
  }

  private var linkNotes: [Note] {
    var notes = viewModel.messages.filter { viewModel.linkPreviews[$0.id] != nil }
    if !trimmedSearchText.isEmpty {
      notes = notes.filter { note in
        guard let preview = viewModel.linkPreviews[note.id] else {
          return false
        }
        return preview.title.localizedStandardContains(trimmedSearchText)
          || (preview.siteURL.host ?? "").localizedStandardContains(trimmedSearchText)
      }
    }
    return notes.sorted { $0.createdAt < $1.createdAt }
  }

  private var voiceMemoNotes: [Note] {
    viewModel.messages.filter { $0.voiceMemoData != nil }.filter { note in
      guard !trimmedSearchText.isEmpty else { return true }
      let transcript: String
      if case let .transcribed(result) = viewModel.voiceMemoStates[note.id] { transcript = result.text } else { transcript = "" }
      return note.content.localizedStandardContains(trimmedSearchText) || transcript.localizedStandardContains(trimmedSearchText)
    }.sorted { $0.createdAt < $1.createdAt }
  }

  private var fileNotes: [Note] {
    viewModel.messages.filter { $0.fileName != nil }.filter { note in
      guard !trimmedSearchText.isEmpty else { return true }
      return (note.fileName ?? note.content).localizedStandardContains(trimmedSearchText)
    }.sorted { $0.createdAt < $1.createdAt }
  }

  @ViewBuilder private var voiceMemoGrid: some View {
    if voiceMemoNotes.isEmpty {
      emptyState(image: .emptyArchive, message: trimmedSearchText.isEmpty ? "아직 주고받은 음성 메모가 없습니다" : "검색 결과가 없습니다")
    } else {
      LazyVStack(alignment: .leading, spacing: 12) {
        ForEach(voiceMemoNotes) { note in
          VoiceMemoCard(note: note)
            .contextMenu { Button(role: .destructive) { requestDelete(note) } label: { Label("삭제하기", systemImage: "trash") } }
        }
      }.padding(16)
    }
  }

  @ViewBuilder private var fileList: some View {
    if fileNotes.isEmpty {
      emptyState(
        image: .emptyArchive,
        message: trimmedSearchText.isEmpty ? "아직 주고받은 파일이 없습니다" : "검색 결과가 없습니다"
      )
    } else {
      LazyVStack(alignment: .leading, spacing: 12) {
        ForEach(fileNotes) { note in
          NavigationLink {
            FilePreviewView(
              note: note,
              downloadState: viewModel.fileDownloadStates[note.id],
              onRetryDownload: { viewModel.retryFileDownload(for: note) },
              onDelete: { viewModel.deleteMessage(id: $0.id) }
            )
          } label: {
            FileCard(
              note: note,
              downloadState: viewModel.fileDownloadStates[note.id],
              onRetryDownload: { viewModel.retryFileDownload(for: note) }
            )
          }
          .buttonStyle(.plain)
          .contextMenu {
            if let fileURL = FileTransferURL.temporaryURL(for: note) {
              ShareLink(item: fileURL, preview: SharePreview(note.fileName ?? "파일")) {
                Label("공유하기", systemImage: "square.and.arrow.up")
              }
            }
            Button(role: .destructive) { requestDelete(note) } label: { Label("삭제하기", systemImage: "trash") }
          }
        }
      }
      .padding(16)
    }
  }

  @ViewBuilder
  private var photoGrid: some View {
    if photoSections.isEmpty {
      emptyState(
        image: trimmedSearchText.isEmpty ? .emptyArchive : .emptyPhoto,
        message: trimmedSearchText.isEmpty ? "아직 주고받은 사진이 없습니다" : "검색 결과가 없습니다"
      )
    } else {
      LazyVStack(alignment: .leading, spacing: 16) {
        ForEach(photoSections) { section in
          Text(section.title)
            .typeStyle(.footnoteEmphasized)
            .foregroundStyle(.gray400)

          LazyVGrid(columns: photoColumns, spacing: 4) {
            ForEach(section.messages) { note in
              if let imageData = note.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(height: 84)
                  .clipped()
                  .clipShape(RoundedRectangle(cornerRadius: 8))
                  .contextMenu {
                    Button {
                      UIPasteboard.general.image = uiImage
                    } label: {
                      Label("복사하기", systemImage: "doc.on.doc")
                    }

                    ShareLink(item: Image(uiImage: uiImage), preview: SharePreview("사진", image: Image(uiImage: uiImage))) {
                      Label("공유하기", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                      requestDelete(note)
                    } label: {
                      Label("삭제하기", systemImage: "trash")
                    }
                  }
              }
            }
          }
        }
      }
      .padding(16)
    }
  }

  @ViewBuilder
  private var linkGrid: some View {
    if linkNotes.isEmpty {
      emptyState(
        image: trimmedSearchText.isEmpty ? .emptyArchive : .emptyLink,
        message: trimmedSearchText.isEmpty ? "아직 주고받은 링크가 없습니다" : "검색 결과가 없습니다"
      )
    } else {
      LazyVGrid(columns: linkColumns, spacing: 12) {
        ForEach(linkNotes) { note in
          if let preview = viewModel.linkPreviews[note.id] {
            LinkPreviewCard(preview: preview)
              .contextMenu {
                Button {
                  UIPasteboard.general.string = preview.siteURL.absoluteString
                } label: {
                  Label("복사하기", systemImage: "doc.on.doc")
                }

                ShareLink(item: preview.siteURL) {
                  Label("공유하기", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                  requestDelete(note)
                } label: {
                  Label("삭제하기", systemImage: "trash")
                }
              }
          }
        }
      }
      .padding(16)
    }
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

  private func emptyState(image: ImageResource, message: String) -> some View {
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

  private func requestDelete(_ note: Note) {
    confirmationAlert = DestructiveConfirmationAlert(
      title: "이 항목을\n삭제하시겠습니까?",
      message: "삭제한 항목은 복구할 수 없습니다.",
      acknowledgementText: nil
    ) {
      if viewModel.deleteMessage(id: note.id) {
        toast = Toast(message: "삭제되었습니다", style: .success, icon: "trash.fill")
      } else {
        toast = Toast(message: "삭제에 실패했습니다", style: .failure)
      }
    }
  }

  /// 다운로드 실패는 특정 카드에 계속 붙어있는 텍스트가 아니라 토스트로 한 번만 알려줍니다.
  private func handleFileDownloadStateChange(_ states: [Note.ID: ChatViewModel.FileDownloadState]) {
    for (id, state) in states {
      guard state == .failed else {
        toastedFailedFileDownloadIds.remove(id)
        continue
      }
      guard !toastedFailedFileDownloadIds.contains(id) else { continue }
      toastedFailedFileDownloadIds.insert(id)

      toast = Toast(
        message: "파일 다운로드 실패했습니다",
        style: .failure,
        action: Toast.Action(title: "다시 시도") {
          if let note = viewModel.messages.first(where: { $0.id == id }) {
            viewModel.retryFileDownload(for: note)
          }
        }
      )
    }
  }
}
