import SwiftUI
import UIKit

/// 아카이브 미리보기 카드의 "더 보기"에서 진입하는, 한 카테고리의 전체 목록 화면입니다.
/// 상단 탭으로 다른 카테고리로도 바로 전환할 수 있습니다.
struct ArchiveCategoryListView: View {
  let viewModel: ChatViewModel
  let startingCategory: ArchiveCategory

  @State private var selectedCategory: ArchiveCategory
  @State private var isSearching = false
  @State private var searchText = ""
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?
  @State private var toastedFailedFileDownloadIds: Set<Note.ID> = []

  private let photoColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)
  private let linkColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

  init(viewModel: ChatViewModel, startingCategory: ArchiveCategory) {
    self.viewModel = viewModel
    self.startingCategory = startingCategory
    _selectedCategory = State(initialValue: startingCategory)
  }

  var body: some View {
    VStack(spacing: 0) {
      categoryPicker

      ScrollView {
        switch selectedCategory {
        case .text:
          textList
        case .photos:
          photoGrid
        case .voiceMemos:
          voiceMemoGrid
        case .files:
          fileList
        case .links:
          linkGrid
        }
      }
    }
    .background(Color.gray50)
    .navigationTitle(selectedCategory.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          isSearching = true
        } label: {
          Image(systemName: "magnifyingglass")
            .foregroundStyle(.gray950)
        }
        .accessibilityLabel("검색")
      }
    }
    .searchable(text: $searchText, isPresented: $isSearching, prompt: "검색")
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
    .onChange(of: viewModel.fileDownloadStates) { _, newStates in
      handleFileDownloadStateChange(newStates)
    }
  }

  private var categoryPicker: some View {
    HStack(spacing: 0) {
      ForEach(ArchiveCategory.allCases, id: \.self) { category in
        Button {
          selectedCategory = category
        } label: {
          VStack(spacing: 8) {
            Text(category.title)
              .typeStyle(.subheadline)
              .foregroundStyle(selectedCategory == category ? .gray950 : .gray400)

            Rectangle()
              .fill(selectedCategory == category ? Color.violet500 : Color.clear)
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

  private var textNotes: [Note] {
    var notes = viewModel.messages.filter { $0.imageData == nil && $0.voiceMemoData == nil && $0.fileName == nil }
    if !trimmedSearchText.isEmpty {
      notes = notes.filter { viewModel.matches($0, searchText: trimmedSearchText) }
    }
    return notes.sorted { $0.createdAt < $1.createdAt }
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

  @ViewBuilder private var textList: some View {
    if textNotes.isEmpty {
      archiveEmptyState(image: .emptyArchive, message: trimmedSearchText.isEmpty ? "아직 주고받은 텍스트가 없습니다" : "검색 결과가 없습니다")
    } else {
      LazyVStack(alignment: .leading, spacing: 16) {
        ForEach(textNotes) { note in
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
              .lineLimit(3)
              .truncationMode(.tail)
          }
          .padding(16)
          .background(.white)
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .contextMenu {
            Button {
              UIPasteboard.general.string = note.content
            } label: {
              Label("복사하기", systemImage: "doc.on.doc")
            }
            Button(role: .destructive) { requestDelete(note) } label: { Label("삭제하기", systemImage: "trash") }
          }
        }
      }
      .padding(16)
    }
  }

  @ViewBuilder private var voiceMemoGrid: some View {
    if voiceMemoNotes.isEmpty {
      archiveEmptyState(image: .emptyArchive, message: trimmedSearchText.isEmpty ? "아직 주고받은 음성 메모가 없습니다" : "검색 결과가 없습니다")
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
      archiveEmptyState(
        image: .emptyArchive,
        message: trimmedSearchText.isEmpty ? "아직 주고받은 파일이 없습니다" : "검색 결과가 없습니다"
      )
    } else {
      LazyVStack(alignment: .leading, spacing: 12) {
        ForEach(fileNotes) { note in
          // NavigationLink의 label 안에 다운로드 재시도 Button까지 같이 넣으면 탭 히트테스트가
          // 꼬여서(어느 탭이 어느 컨트롤로 가는지 불명확해짐), FileCard는 순수 표시용으로만 두고
          // 재시도 배지는 NavigationLink와 형제(ZStack의 별도 레이어)로 둡니다.
          ZStack(alignment: .bottomTrailing) {
            NavigationLink {
              FilePreviewView(viewModel: viewModel, noteID: note.id)
            } label: {
              FileCard(note: note, downloadState: viewModel.fileDownloadStates[note.id])
            }
            .buttonStyle(.plain)

            if note.fileData == nil {
              downloadRetryBadge(for: note)
                .padding(.trailing, 6)
                .padding(.bottom, 6)
            }
          }
          .contextMenu {
            if let fileURL = viewModel.fileTransferURLs[note.id] {
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
      archiveEmptyState(
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
      archiveEmptyState(
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

  @ViewBuilder
  private func downloadRetryBadge(for note: Note) -> some View {
    switch viewModel.fileDownloadStates[note.id] {
    case .checking:
      FileDownloadBadgeIcon { ProgressView().controlSize(.mini).tint(.gray500) }
    case .failed, nil:
      Button(action: { viewModel.retryFileDownload(for: note) }) {
        FileDownloadBadgeIcon {
          Image(systemName: "arrow.down")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.gray500)
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("파일 다운로드")
    }
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
