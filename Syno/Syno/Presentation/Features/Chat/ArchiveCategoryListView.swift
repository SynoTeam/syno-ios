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
  /// 사진·음성 목록에서 여러 개를 고르는 선택 모드입니다. 채팅의 선택 모드와 같은 상태를 씁니다 (#142, #144).
  /// 선택 중에는 상단 탭을 막으므로 한 번에 한 카테고리에서만 고릅니다.
  @State private var selection = ChatSelectionState()
  /// 파일 앱 저장 위치 선택 화면에 넘길 음성 메모 파일입니다 (#144).
  @State private var voiceExport: VoiceMemoExportRequest?

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
        // 선택 중에 다른 카테고리로 넘어가 선택이 꼬이지 않게 막는다.
        .disabled(selection.isActive)

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
    .safeAreaInset(edge: .bottom) {
      if selection.isActive {
        selectionBar
      }
    }
    // 시안: 아카이브 목록 화면은 흰 배경, 카드는 gray50 (#142).
    .background(Color.white)
    .navigationTitle(navigationTitle)
    .navigationBarTitleDisplayMode(.inline)
    // 사진 선택은 "취소"가 뒤로 가기 자리를 쓰고, 음성 선택은 시안대로 뒤로 가기를 두고 오른쪽에 X를 둔다.
    .synoBackButton(isHidden: selection.isActive && selectedCategory == .photos)
    .toolbar(.hidden, for: .tabBar)
    .toolbar { toolbarContent }
    // 지워졌거나 검색으로 화면에서 사라진 사진은 선택에서 뺀다. 보이지 않는 사진이 함께 삭제되지 않게 한다.
    .onChange(of: visibleSelectableIDs) { _, ids in
      selection.retain(only: ids)
    }
    .searchable(text: $searchText, isPresented: $isSearching, prompt: "검색")
    .onChange(of: isSearching) { _, isSearching in
      if !isSearching {
        searchText = ""
      }
    }
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
    .onChange(of: viewModel.fileDownloadStates) { _, newStates in
      handleFileDownloadStateChange(newStates)
    }
    .sheet(isPresented: exportPickerBinding) {
      if let voiceExport {
        DocumentExportPicker(urls: voiceExport.urls) { didSave in
          self.voiceExport = nil
          if didSave {
            viewModel.markVoiceMemosSaved(voiceExport.noteIDs)
            toast = Toast(message: "파일에 저장되었습니다", style: .success)
            if selection.isActive { selection.end() }
          }
        }
        .ignoresSafeArea()
      }
    }
  }

  private var navigationTitle: String {
    guard selection.isActive else { return selectedCategory.title }
    return selection.count > 0 ? "\(selection.count)개 선택" : "선택하기"
  }

  private var exportPickerBinding: Binding<Bool> {
    Binding(get: { voiceExport != nil }, set: { if !$0 { voiceExport = nil } })
  }

  private var categoryPicker: some View {
    HStack(spacing: 0) {
      ForEach(ArchiveCategory.allCases, id: \.self) { category in
        Button {
          selectedCategory = category
        } label: {
          VStack(spacing: 8) {
            // 선택된 탭은 볼드 violet600으로 강조한다 (#142).
            Text(category.title)
              .typeStyle(selectedCategory == category ? .subheadlineEmphasized : .subheadline)
              .foregroundStyle(selectedCategory == category ? .violet600 : .gray400)

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

  /// 지금 사진 목록에 보이는 사진입니다(검색 결과 반영).
  private var visiblePhotoIDs: Set<Note.ID> {
    Set(photoSections.flatMap { $0.messages.map(\.id) })
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

  /// 선택 모드에서 고를 수 있는, 지금 화면에 보이는 항목입니다.
  private var visibleSelectableIDs: Set<Note.ID> {
    switch selectedCategory {
    case .photos: visiblePhotoIDs
    case .voiceMemos: Set(voiceMemoNotes.map(\.id))
    default: []
    }
  }

  private var fileNotes: [Note] {
    viewModel.messages.filter { $0.fileName != nil }.filter { note in
      guard !trimmedSearchText.isEmpty else { return true }
      return (note.fileName ?? note.content).localizedStandardContains(trimmedSearchText)
    }.sorted { $0.createdAt < $1.createdAt }
  }

  @ViewBuilder private var textList: some View {
    if textNotes.isEmpty {
      archiveEmptyState(image: trimmedSearchText.isEmpty ? .emptyText : .emptyTextSearch, message: trimmedSearchText.isEmpty ? "채팅창에 텍스트를 전송하면\n확인 가능합니다." : "검색 결과가 없습니다")
    } else {
      LazyVStack(alignment: .leading, spacing: 16) {
        ForEach(textNotes) { note in
          VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
              Image(.logo)
                .profileImage(data: note.profileImageData, size: 32)

              Text(ArchiveFormatters.contactNameText(note.contactName))
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
          .background(.gray50)
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .contextMenu {
            Button {
              UIPasteboard.general.string = note.content
            } label: {
              Label("복사하기", icon: .copy)
            }
            Button(role: .destructive) { requestDelete(note) } label: { Label("삭제하기", destructiveIcon: .trash) }
          }
        }
      }
      .padding(16)
    }
  }

  @ViewBuilder private var voiceMemoGrid: some View {
    if voiceMemoNotes.isEmpty {
      archiveEmptyState(image: trimmedSearchText.isEmpty ? .emptyVoice : .emptyVoiceSearch, message: trimmedSearchText.isEmpty ? "채팅창에 음성 메모를 전송하면\n확인 가능합니다." : "검색 결과가 없습니다")
    } else {
      ArchiveVoiceMemoList(
        viewModel: viewModel,
        notes: voiceMemoNotes,
        selection: $selection,
        onExport: exportVoiceMemos,
        onRequestDelete: requestDelete,
        onToast: { toast = $0 }
      )
    }
  }

  // MARK: - 선택 모드 (#142 사진, #144 음성)

  @ViewBuilder private var selectionBar: some View {
    if selectedCategory == .voiceMemos {
      voiceSelectionBar
    } else {
      ChatSelectionBar(selectedCount: selection.count, onDelete: requestPhotoSelectionDeletion)
    }
  }

  /// 시안: 파일에 저장, 공유, 삭제. 아무것도 고르지 않으면 흐리게 막는다.
  private var voiceSelectionBar: some View {
    let notes = selectedVoiceMemoNotes
    let isEmpty = notes.isEmpty
    // 고른 메모를 모두 이미 저장했으면 저장 버튼을 막는다.
    let isAllSaved = !isEmpty && notes.allSatisfy { viewModel.savedVoiceMemoIDs.contains($0.id) }
    return PreviewActionBar {
      Button { exportVoiceMemos(notes) } label: { PreviewActionIcon(.download) }
        .buttonStyle(.plain)
        .accessibilityLabel("파일에 저장")
        .disabled(isEmpty || isAllSaved)
        .opacity(isAllSaved ? 0.4 : 1)

      // 음성 공유는 변환 텍스트로 한다. 여러 개면 제목과 변환 텍스트를 이어 붙인다.
      ShareLink(item: viewModel.voiceMemoShareItem(for: notes), preview: SharePreview("음성 메모 \(notes.count)개")) {
        PreviewActionIcon(.share)
      }
        .buttonStyle(.plain)
        .accessibilityLabel("공유하기")
        .disabled(isEmpty)

      Button { requestVoiceSelectionDeletion() } label: { PreviewActionIcon(.trash) }
        .buttonStyle(.plain)
        .accessibilityLabel("선택한 음성 메모 삭제")
        .disabled(isEmpty)
    }
    .opacity(isEmpty ? 0.5 : 1)
    .padding(.horizontal, 16)
    .padding(.bottom, 8)
  }

  /// 화면에 보이는 것 중 고른 음성 메모입니다. 목록 순서를 유지합니다.
  private var selectedVoiceMemoNotes: [Note] {
    voiceMemoNotes.filter { selection.selectedIDs.contains($0.id) }
  }

  /// 파일 앱 저장 위치 선택 화면을 띄웁니다. 임시 파일을 만든 뒤 띄웁니다.
  private func exportVoiceMemos(_ notes: [Note]) {
    let requestedIDs = notes.map(\.id)
    let wasSelecting = selection.isActive
    guard !requestedIDs.isEmpty else { return }
    Task {
      let urls = await viewModel.voiceMemoTransferURLs(for: requestedIDs)
      // 파일을 만드는 동안 다른 탭으로 옮겼거나, 검색·삭제·동기화로 목록에서 사라졌거나,
      // 선택이 풀린 메모가 있으면 저장하지 않는다.
      guard selectedCategory == .voiceMemos else { return }
      let visibleIDs = Set(voiceMemoNotes.map(\.id))
      let isStillValid = requestedIDs.allSatisfy { id in
        visibleIDs.contains(id) && (!wasSelecting || selection.selectedIDs.contains(id))
      }
      guard isStillValid, selection.isActive == wasSelecting else { return }
      guard let urls else {
        toast = Toast(message: "저장할 음성 파일을 준비하지 못했습니다. 잠시 후 다시 시도해주세요.", style: .failure)
        return
      }
      voiceExport = VoiceMemoExportRequest(urls: urls, noteIDs: Set(requestedIDs))
    }
  }

  private func requestVoiceSelectionDeletion() {
    let count = selectedVoiceMemoNotes.count
    guard count > 0 else { return }
    confirmationAlert = DestructiveConfirmationAlert(
      title: count > 1 ? "\(count)개의 음성 메모를\n삭제하시겠습니까?" : "이 음성 메모를\n삭제하시겠습니까?",
      message: "삭제한 음성 메모는 복구할 수 없습니다.",
      acknowledgementText: nil
    ) {
      deleteSelectedVoiceMemos()
    }
  }

  private func deleteSelectedVoiceMemos() {
    // 화면에 보이는 메모만 지운다(사진 선택 삭제와 같은 이유).
    let ids = Set(selectedVoiceMemoNotes.map(\.id))
    guard !ids.isEmpty, viewModel.deleteMessages(ids: ids) else {
      toast = Toast(message: "음성 메모를 삭제하지 못했습니다", style: .failure)
      return
    }
    selection.end()
    toast = Toast(message: "음성 메모 \(ids.count)개가 삭제되었습니다", style: .success, icon: .trash)
  }

  @ViewBuilder private var fileList: some View {
    if fileNotes.isEmpty {
      archiveEmptyState(
        image: trimmedSearchText.isEmpty ? .emptyFile : .emptyFileSearch,
        message: trimmedSearchText.isEmpty ? "채팅창에 파일을 전송하면\n확인 가능합니다." : "검색 결과가 없습니다"
      )
    } else {
      // 시안: 폴더 아이콘·이름·용량·다운로드 버튼 한 줄과 구분선으로 된 목록 (#142)
      LazyVStack(alignment: .leading, spacing: 0) {
        ForEach(fileNotes) { note in
          fileRow(note)

          Rectangle()
            .fill(.gray100)
            .frame(height: 1)
        }
      }
      .padding(.horizontal, 16)
    }
  }

  /// 파일 한 줄입니다. 누르면 파일 미리보기로 가고, 오른쪽 버튼은 파일을 기기에 저장합니다.
  /// 미리보기 링크 안에 버튼을 넣으면 어느 탭이 어디로 가는지 꼬이므로 둘을 나란히 둡니다.
  private func fileRow(_ note: Note) -> some View {
    HStack(alignment: .center, spacing: 12) {
      NavigationLink {
        FilePreviewView(viewModel: viewModel, noteID: note.id)
      } label: {
        HStack(alignment: .center, spacing: 16) {
          // 아카이브 첫 화면의 파일 행과 같은 폴더 그림을, 흰 배경 위의 연한 둥근 사각형에 둔다.
          Image(.messageFile)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 31)
            .frame(width: 52, height: 52)
            .background(.gray50, in: RoundedRectangle(cornerRadius: 16))

          VStack(alignment: .leading, spacing: 2) {
            Text(note.fileName ?? note.content)
              .typeStyle(.bodyEmphasized)
              .foregroundStyle(.gray950)
              .lineLimit(1)
              .truncationMode(.middle)
            Text("Size \(Self.fileSizeText(note.fileSize))")
              .typeStyle(.subheadline)
              .foregroundStyle(.gray500)
          }

          Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .contextMenu {
        if let fileURL = viewModel.fileTransferURLs[note.id] {
          ShareLink(item: fileURL, preview: SharePreview(note.fileName ?? "파일")) {
            Label("공유하기", icon: .share)
          }
        }
        Button(role: .destructive) { requestDelete(note) } label: { Label("삭제하기", destructiveIcon: .trash) }
      }

      fileSaveButton(for: note)
    }
    // Figma: 위아래 16, 좌우 0
    .padding(.vertical, 16)
  }

  /// 시안처럼 숫자와 단위를 붙여 씁니다(예: 26.6MB).
  private static func fileSizeText(_ bytes: Int?) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes ?? 0), countStyle: .file)
      .replacingOccurrences(of: " ", with: "")
  }

  /// 받은 파일은 공유 시트를 열어 '파일' 앱 등 기기에 저장하고, 아직 iCloud에서 못 받은 파일은 먼저 받습니다.
  @ViewBuilder
  private func fileSaveButton(for note: Note) -> some View {
    if note.fileData == nil {
      if viewModel.fileDownloadStates[note.id] == .checking {
        ProgressView()
          .controlSize(.small)
          .tint(.gray500)
          .frame(width: 36, height: 36)
      } else {
        Button {
          viewModel.retryFileDownload(for: note)
        } label: {
          fileSaveIcon
        }
        .buttonStyle(CirclePressButtonStyle())
        .accessibilityLabel("파일 받기")
      }
    } else if let fileURL = viewModel.fileTransferURLs[note.id] {
      ShareLink(item: fileURL, preview: SharePreview(note.fileName ?? "파일")) {
        fileSaveIcon
      }
      .buttonStyle(CirclePressButtonStyle())
      .accessibilityLabel("기기에 저장")
    } else {
      // 저장용 임시 파일이 아직 없으면(준비 중이거나 준비에 실패) 눌렀을 때 이유를 알려 준다.
      Button {
        toast = Toast(message: "저장할 파일을 준비하지 못했습니다. 잠시 후 다시 시도해주세요.", style: .failure)
      } label: {
        fileSaveIcon
          .opacity(0.4)
      }
      .buttonStyle(CirclePressButtonStyle())
      .accessibilityLabel("기기에 저장")
    }
  }

  private var fileSaveIcon: some View {
    Image(.download)
      .resizable()
      .renderingMode(.template)
      .foregroundStyle(.gray600)
      .frame(width: 24, height: 24)
      .frame(width: 36, height: 36)
  }

  @ViewBuilder
  private var photoGrid: some View {
    if photoSections.isEmpty {
      archiveEmptyState(
        image: trimmedSearchText.isEmpty ? .emptyPhoto : .emptyPhotoSearch,
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
                photoGridItem(note, image: uiImage)
              }
            }
          }
        }
      }
      .padding(16)
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    if selection.isActive, selectedCategory == .voiceMemos {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          selection.end()
        } label: {
          Image(.close)
            .resizable()
            .renderingMode(.template)
            .frame(width: 20, height: 20)
            .foregroundStyle(.gray950)
        }
        .accessibilityLabel("선택 끝내기")
      }
    } else if selection.isActive {
      ToolbarItem(placement: .topBarLeading) {
        Button("취소") {
          selection.end()
        }
      }
    } else {
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
  }

  /// 사진 목록의 한 칸입니다. 선택 모드에서는 누르면 선택이 바뀌고, 평소에는 미리보기로 이동합니다.
  @ViewBuilder
  private func photoGridItem(_ note: Note, image uiImage: UIImage) -> some View {
    if selection.isActive {
      Button {
        selection.toggle([note.id])
      } label: {
        photoCell(uiImage)
          .overlay(alignment: .topTrailing) {
            ChatSelectionIndicator(isSelected: selection.isSelected([note.id]))
              .scaleEffect(0.8)
              .padding(4)
          }
      }
      .buttonStyle(.plain)
      .accessibilityLabel(selection.isSelected([note.id]) ? "선택된 사진" : "사진 선택")
    } else {
      NavigationLink {
        PhotoPreviewView(viewModel: viewModel, noteID: note.id)
      } label: {
        photoCell(uiImage)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("사진 크게 보기")
      .contextMenu {
        Button {
          selection.begin(with: [note.id])
        } label: {
          Label("선택하기", icon: .checkCircleFilled)
        }

        Button {
          UIPasteboard.general.image = uiImage
        } label: {
          Label("복사하기", icon: .copy)
        }

        ShareLink(item: Image(uiImage: uiImage), preview: SharePreview("사진", image: Image(uiImage: uiImage))) {
          Label("공유하기", icon: .share)
        }

        Button(role: .destructive) {
          requestDelete(note)
        } label: {
          Label("삭제하기", destructiveIcon: .trash)
        }
      }
    }
  }

  /// 사진 한 칸의 모양입니다. 사진의 원래 비율이 칸 크기에 영향을 주지 않도록, 정사각형 칸을 먼저 만들고 사진은 그 위에 덮어 자른다.
  private func photoCell(_ image: UIImage) -> some View {
    Color.clear
      .aspectRatio(1, contentMode: .fit)
      .overlay {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .contentShape(RoundedRectangle(cornerRadius: 8))
  }

  private func requestPhotoSelectionDeletion() {
    let count = selection.count
    guard count > 0 else {
      return
    }
    confirmationAlert = DestructiveConfirmationAlert(
      title: count > 1 ? "\(count)장의 사진을\n삭제하시겠습니까?" : "이 사진을\n삭제하시겠습니까?",
      message: "삭제한 사진은 복구할 수 없습니다.",
      acknowledgementText: nil
    ) {
      deleteSelectedPhotos()
    }
  }

  private func deleteSelectedPhotos() {
    // 화면에 보이는 사진만 지운다. 선택 정리(onChange)보다 삭제가 먼저 실행되는 경우에도 안전하게 한 번 더 거른다.
    let ids = selection.selectedIDs.intersection(visiblePhotoIDs)
    let deletedCount = ids.count
    guard deletedCount > 0, viewModel.deleteMessages(ids: ids) else {
      toast = Toast(message: "사진을 삭제하지 못했습니다", style: .failure)
      return
    }
    selection.end()
    toast = Toast(message: "사진 \(deletedCount)장이 삭제되었습니다", style: .success, icon: .trash)
  }

  @ViewBuilder
  private var linkGrid: some View {
    if linkNotes.isEmpty {
      archiveEmptyState(
        image: trimmedSearchText.isEmpty ? .emptyData : .emptyDataSearch,
        message: trimmedSearchText.isEmpty ? "아직 주고받은 링크가 없습니다" : "검색 결과가 없습니다"
      )
    } else {
      LazyVGrid(columns: linkColumns, spacing: 12) {
        ForEach(linkNotes) { note in
          if let preview = viewModel.linkPreviews[note.id] {
            // 시안: 목록의 링크 카드는 높이 184로 모두 같게 (#142)
            LinkPreviewCard(preview: preview, height: 184, background: .gray50)
              .contextMenu {
                Button {
                  UIPasteboard.general.string = preview.siteURL.absoluteString
                } label: {
                  Label("복사하기", icon: .copy)
                }

                ShareLink(item: preview.siteURL) {
                  Label("공유하기", icon: .share)
                }

                Button(role: .destructive) {
                  requestDelete(note)
                } label: {
                  Label("삭제하기", destructiveIcon: .trash)
                }
              }
          }
        }
      }
      .padding(16)
    }
  }

  private func requestDelete(_ note: Note) {
    confirmationAlert = DestructiveConfirmationAlert(
      title: "이 항목을\n삭제하시겠습니까?",
      message: "삭제한 항목은 복구할 수 없습니다.",
      acknowledgementText: nil
    ) {
      if viewModel.deleteMessage(id: note.id) {
        toast = Toast(message: "삭제되었습니다", style: .success, icon: .trash)
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

/// 파일 앱에 저장할 음성 메모 파일과, 저장에 성공하면 "저장함"으로 표시할 메모입니다.
private struct VoiceMemoExportRequest {
  let urls: [URL]
  let noteIDs: Set<Note.ID>
}

/// 누르는 동안 아이콘 뒤에 회색 원이 생기는 버튼 모양입니다(시안의 파일 다운로드, 음성 카드 버튼).
struct CirclePressButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(configuration.isPressed ? Color.gray100 : Color.clear, in: Circle())
      .contentShape(Circle())
  }
}
