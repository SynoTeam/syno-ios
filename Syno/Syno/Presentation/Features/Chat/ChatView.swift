//
//  ChatView.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 연락처별로 나에게 보내는 형식의 기록을 남기는 채팅 화면입니다.
struct ChatView: View {
  @State private var viewModel: ChatViewModel
  @State private var timeRevealOffset: CGFloat = 0
  /// 검색 결과에서 들어왔을 때 처음 보여줄 메시지입니다. 이동을 마치면 비웁니다.
  @State private var pendingInitialMessageID: Note.ID?
  @State private var highlightedMessageID: Note.ID?
  @State private var selectedPhotoItems: [PhotosPickerItem] = []
  @State private var isShowingPhotosPicker = false
  @State private var isShowingCamera = false
  @State private var pendingCameraImage: UIImage?
  @State private var pendingPhotoConfirmation: PhotoConfirmationRequest?
  @State private var isShowingFilePicker = false
  @State private var isShowingVoiceMemoPicker = false
  @State private var isMessageSearchPresented = false
  @State private var currentMatchIndex = 0
  @State private var isShowingArchive = false
  @State private var deniedPermission: PermissionKind?
  /// 채팅 안에서 여러 메시지를 골라 삭제하는 선택 모드입니다.
  @State private var selection = ChatSelectionState()
  @State private var deletionAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?
  @State private var fullTextNote: Note?
  @State private var photoPreviewNoteID: Note.ID?
  @State private var filePreviewNoteID: Note.ID?
  @State private var toastedFailedFileDownloadIds: Set<Note.ID> = []
  @State private var voiceRecorder = VoiceRecorder()
  @FocusState private var isInputFocused: Bool

  init(
    contact: Contact,
    initialMessageID: Note.ID? = nil,
    repository: any NoteRepository,
    imageAnalyzer: any NoteImageAnalyzing,
    imageAnalysisRepository: any NoteImageAnalysisRepository,
    linkPreviewFetcher: any NoteLinkPreviewFetching = NoopNoteLinkPreviewFetcher(),
    linkPreviewRepository: any NoteLinkPreviewRepository = NoopNoteLinkPreviewRepository(),
    labelTranslator: any LabelTranslating,
    voiceTranscriber: any NoteVoiceTranscribing,
    voiceTranscriptRepository: any NoteVoiceTranscriptRepository,
    analytics: any AnalyticsTracking = NoopAnalyticsTracking()
  ) {
    _pendingInitialMessageID = State(initialValue: initialMessageID)
    _viewModel = State(
      initialValue: ChatViewModel(
        contact: contact,
        repository: repository,
        imageAnalyzer: imageAnalyzer,
        imageAnalysisRepository: imageAnalysisRepository,
        linkPreviewFetcher: linkPreviewFetcher,
        linkPreviewRepository: linkPreviewRepository,
        labelTranslator: labelTranslator,
        voiceTranscriber: voiceTranscriber,
        voiceTranscriptRepository: voiceTranscriptRepository,
        analytics: analytics
      )
    )
  }

  var body: some View {
    navigationContent
      .onChange(of: selectedPhotoItems) { _, items in
        guard !items.isEmpty else {
          return
        }
        Task {
          await loadImages(from: items)
          selectedPhotoItems = []
        }
      }
      .photosPicker(
        isPresented: $isShowingPhotosPicker,
        selection: $selectedPhotoItems,
        maxSelectionCount: Self.maxPhotoSelectionCount,
        matching: .images
      )
      .sheet(isPresented: $isShowingCamera, onDismiss: presentPendingCameraImage) {
        CameraPickerView { image in
          pendingCameraImage = image
        }
        .ignoresSafeArea()
      }
      .sheet(item: $pendingPhotoConfirmation) { request in
        ChatPhotoConfirmationView(photos: request.photos) { datas in
          // 여러 장이면 한 묶음으로 저장되어 채팅에서 하나의 콜라주 말풍선으로 보인다.
          Task { await viewModel.sendImages(datas) }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
      }
      .sheet(isPresented: $isShowingFilePicker) {
        FileDocumentPicker { url in
          Task { await viewModel.sendFile(url: url) }
        }
      }
      .modifier(presentedModifier)
  }

  /// 화면 본체입니다. 메시지 목록과 하단 바(입력창 또는 선택 모드 삭제 바)로 구성합니다.
  private var content: some View {
    VStack(spacing: 0) {
      messagesScrollView
      if selection.isActive {
        ChatSelectionBar(selectedCount: selection.count, onDelete: requestSelectionDeletion)
      } else {
        messageInputBar
      }
    }
    .background(Color.gray50)
    .toast(item: $toast)
    .onChange(of: viewModel.messages.map(\.id)) { _, messageIDs in
      selection.retain(only: Set(messageIDs))
    }
    .onChange(of: viewModel.fileDownloadStates) { _, newStates in
      handleFileDownloadStateChange(newStates)
    }
  }

  /// 제목, 툴바, 검색 등 네비게이션 영역 설정을 붙인 화면입니다.
  private var navigationContent: some View {
    content
      .navigationTitle(selection.isActive ? "\(selection.count)개 선택" : viewModel.contact.name)
      .navigationBarBackButtonHidden(selection.isActive)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar(.hidden, for: .tabBar)
      .toolbar { toolbarContent }
      .navigationDestination(isPresented: $isShowingArchive) {
        ArchiveView(viewModel: viewModel)
      }
      .background { messageSearchHost }
      .onChange(of: isMessageSearchPresented) { _, isPresented in
        if !isPresented {
          viewModel.messageSearchText = ""
          currentMatchIndex = 0
        }
      }
      .tint(.gray950)
      .trackScreen("chat")
      .scrollDismissesKeyboard(.interactively)
  }

  /// 검색 아이콘을 눌렀을 때만 시스템 검색창을 붙입니다.
  /// 항상 붙여 두면 목록을 맨 위로 당길 때 검색창이 따로 나타나므로, 본체가 다시 만들어지지 않게 background에 둡니다.
  @ViewBuilder
  private var messageSearchHost: some View {
    if isMessageSearchPresented {
      Color.clear
        .searchable(
          text: binding(\.messageSearchText),
          isPresented: $isMessageSearchPresented,
          prompt: "이 채팅에서 검색"
        )
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    if selection.isActive {
      ToolbarItem(placement: .topBarLeading) {
        Button("취소") {
          selection.end()
        }
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button("선택 해제") {
          selection.clearSelection()
        }
        .disabled(selection.isEmpty)
      }
    } else {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          isInputFocused = false
          isMessageSearchPresented = true
        } label: {
          Image(.search)
            .renderingMode(.template)
        }
        .accessibilityLabel("메시지 검색")

        Button {
          isShowingArchive = true
        } label: {
          Image(.menu)
            .renderingMode(.template)
        }
        .accessibilityLabel("아카이브")
      }
    }
  }

  /// 메시지 로드, 오류 알럿, 전체 보기 시트, 파일 미리보기, 삭제 확인 알럿을 붙이는 modifier입니다.
  private var presentedModifier: some ViewModifier {
    ChatPresentedModifier(
      loadMessages: { await viewModel.loadMessages() },
      persistenceError: persistenceErrorBinding,
      persistenceErrorMessage: viewModel.persistenceError ?? "",
      clearPersistenceError: viewModel.clearPersistenceError,
      fullTextNote: $fullTextNote,
      filePreviewNoteID: $filePreviewNoteID,
      deletionAlert: $deletionAlert,
      deniedPermission: $deniedPermission,
      photoPreviewNoteID: $photoPreviewNoteID,
      isShowingVoiceMemoPicker: $isShowingVoiceMemoPicker,
      onPickVoiceMemo: { url in Task { await viewModel.sendVoiceMemoFile(url: url) } },
      fullTextView: { note in fullTextView(for: note) },
      filePreviewView: { noteID in FilePreviewView(viewModel: viewModel, noteID: noteID) },
      photoPreviewView: { noteID in PhotoPreviewView(viewModel: viewModel, noteID: noteID) }
    )
  }

  private func fullTextView(for note: Note) -> some View {
    FullTextMessageView(
      note: note,
      onDelete: { note in
        let didDelete = deleteMessage(note)
        if didDelete {
          toast = Toast(message: "메시지가 삭제되었습니다", style: .success, icon: "trash.fill")
        }
        return didDelete
      }
    )
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  private var messagesScrollView: some View {
    ScrollViewReader { proxy in
      VStack(spacing: 0) {
        ScrollView {
          if viewModel.messages.isEmpty && viewModel.pendingMessages.isEmpty {
            ChatEmptyStateView()
          } else {
            LazyVStack(alignment: .trailing, spacing: 12) {
              ForEach(viewModel.messageSections) { section in
                ChatDateDivider(title: section.title)

                ForEach(section.items) { item in
                  messageRow(for: item)
                }
              }

              ForEach(viewModel.pendingMessages) { pendingMessage in
                ChatMessageBubble(
                  note: pendingMessage.note,
                  pendingStatus: pendingMessage.status,
                  onRetry: {
                    viewModel.retryPendingMessage(id: pendingMessage.id)
                  }
                )
                .id(pendingMessage.id)
              }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
          }
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(timeRevealGesture)
        .overlay(alignment: .bottom) {
          if isMessageSearchPresented, !viewModel.messageSearchResults.isEmpty {
            matchNavigator(with: proxy)
          }
        }
        .onAppear {
          guard !scrollToInitialMessageIfNeeded(with: proxy) else {
            return
          }
          scrollToLatestMessage(with: proxy, animated: false)
        }
        .onChange(of: viewModel.messages.last?.id) { _, messageId in
          guard !scrollToInitialMessageIfNeeded(with: proxy) else {
            return
          }
          scrollToMessage(messageId, with: proxy)
        }
        .onChange(of: viewModel.pendingMessages.last?.id) { _, pendingMessageID in
          guard let pendingMessageID else {
            return
          }
          withAnimation(.snappy(duration: 0.2)) {
            proxy.scrollTo(pendingMessageID, anchor: .bottom)
          }
        }
        .onChange(of: isInputFocused) { _, isFocused in
          if isFocused {
            scrollToLatestMessageAfterKeyboardAppears(with: proxy)
          }
        }
        .onChange(of: viewModel.messageSearchText) { _, _ in
          currentMatchIndex = max(0, viewModel.messageSearchResults.count - 1)
          scrollToCurrentMatch(with: proxy)
        }
      }
    }
  }

  /// 목록을 왼쪽으로 밀면 말풍선이 따라 밀리며 시간이 나타나고, 손을 떼면 돌아옵니다.
  private var timeRevealGesture: some Gesture {
    DragGesture(minimumDistance: 12)
      .onChanged { value in
        guard !selection.isActive else {
          return
        }
        let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
        guard isHorizontal || timeRevealOffset > 0 else {
          return
        }
        let distance = max(0, -value.translation.width)
        // 최대 거리에 가까워질수록 저항이 생기도록 줄인다.
        let limit = Self.maxTimeRevealOffset
        timeRevealOffset = distance <= limit ? distance : limit + (distance - limit) * 0.2
      }
      .onEnded { _ in
        withAnimation(.snappy(duration: 0.25)) {
          timeRevealOffset = 0
        }
      }
  }

  private static let maxTimeRevealOffset: CGFloat = 64

  private func matchNavigator(with proxy: ScrollViewProxy) -> some View {
    HStack(spacing: 16) {
      Text("\(currentMatchIndex + 1)/\(viewModel.messageSearchResults.count)")
        .typeStyle(.footnoteEmphasized)
        .foregroundStyle(.white)

      HStack(spacing: 4) {
        Button {
          goToPreviousMatch(with: proxy)
        } label: {
          Image(systemName: "chevron.up")
            .frame(width: 28, height: 28)
        }
        .disabled(currentMatchIndex <= 0)

        Button {
          goToNextMatch(with: proxy)
        } label: {
          Image(systemName: "chevron.down")
            .frame(width: 28, height: 28)
        }
        .disabled(currentMatchIndex >= viewModel.messageSearchResults.count - 1)
      }
      .foregroundStyle(.white)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(Color.gray900)
    .clipShape(Capsule())
    .padding(.bottom, 12)
  }

  private func goToPreviousMatch(with proxy: ScrollViewProxy) {
    guard currentMatchIndex > 0 else {
      return
    }
    currentMatchIndex -= 1
    scrollToCurrentMatch(with: proxy)
  }

  private func goToNextMatch(with proxy: ScrollViewProxy) {
    guard currentMatchIndex < viewModel.messageSearchResults.count - 1 else {
      return
    }
    currentMatchIndex += 1
    scrollToCurrentMatch(with: proxy)
  }

  private func scrollToCurrentMatch(with proxy: ScrollViewProxy) {
    guard viewModel.messageSearchResults.indices.contains(currentMatchIndex) else {
      return
    }
    scrollToMessage(viewModel.messageSearchResults[currentMatchIndex].id, with: proxy)
  }

  /// + 메뉴 항목의 라벨입니다. 프로젝트 아이콘 에셋을 템플릿으로 그려 시스템 아이콘처럼 보이게 합니다.
  private func menuLabel(_ title: String, icon: ImageResource) -> some View {
    Label {
      Text(title)
    } icon: {
      Image(icon)
        .renderingMode(.template)
    }
  }

  private var messageInputBar: some View {
    HStack(alignment: .bottom, spacing: 10) {
      Menu {
        Button {
          Task { await openCamera() }
        } label: {
          menuLabel("카메라", icon: .camera)
        }

        Button {
          isShowingPhotosPicker = true
        } label: {
          menuLabel("앨범", icon: .image)
        }

        Button {
          isShowingFilePicker = true
        } label: {
          menuLabel("파일", icon: .document)
        }

        Button {
          isShowingVoiceMemoPicker = true
        } label: {
          menuLabel("음성 메모", icon: .sliders)
        }
      } label: {
        Image(.plus)
          .resizable()
          .renderingMode(.template)
          .foregroundStyle(.gray700)
          .frame(width: 22, height: 22)
          .frame(width: 44, height: 44)
          .background(.gray100)
          .clipShape(Circle())
      }
      // 메뉴가 버튼 위로 열릴 때 iOS가 순서를 뒤집지 않고 선언한 순서대로 위에서 아래로 보여준다.
      .menuOrder(.fixed)
      .accessibilityLabel("메모 추가")

      inputField
    }
    .padding(.horizontal, 14)
    .padding(.top, 10)
    .padding(.bottom, 10)
    .background(Color.gray50)
  }

  /// 내용에 따라 세로로 늘어나는 입력 필드입니다. 전송 버튼은 필드 안쪽 오른쪽 아래에 고정됩니다.
  /// 최대 6줄까지 늘어나고 그 이후에는 필드 안에서 스크롤됩니다.
  private var inputField: some View {
    HStack(alignment: .bottom, spacing: 8) {
      if voiceRecorder.isRecording {
        // Figma처럼 파형과 시간을 오른쪽(정지 버튼 쪽)으로 모아 보여준다.
        HStack(spacing: 12) {
          Spacer(minLength: 0)

          HStack(spacing: 1.5) {
            ForEach(voiceRecorder.levels.indices, id: \.self) { index in
              Capsule()
                .fill(Color.violet400)
                .frame(width: 2, height: max(6, voiceRecorder.levels[index] * 30))
                .animation(.easeInOut(duration: 0.15), value: voiceRecorder.levels[index])
            }
          }
          .clipped()
          .animation(.easeInOut(duration: 0.1), value: voiceRecorder.levels.count)

          Text(String(format: "%d:%02d", Int(voiceRecorder.duration) / 60, Int(voiceRecorder.duration) % 60))
            .typeStyle(.subheadline)
            .foregroundStyle(.gray400)
            .monospacedDigit()
        }
        .padding(.leading, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
      } else {
        TextField("메모 입력", text: binding(\.messageText), axis: .vertical)
          .typeStyle(.body)
          .lineLimit(1...6)
          .focused($isInputFocused)
          .padding(.leading, 16)
          .padding(.vertical, 12)
      }

      sendButton
    }
    .padding(.trailing, 2)
    .padding(.bottom, 2)
    .frame(minHeight: 44)
    .background(.gray100)
    .clipShape(RoundedRectangle(cornerRadius: 22))
  }

  private var sendButton: some View {
    Button {
      if voiceRecorder.isRecording, let memo = voiceRecorder.stop() {
        Task { await viewModel.sendVoiceMemo(audioData: memo.data, duration: memo.duration, waveform: memo.waveform) }
      } else if viewModel.canSend {
        viewModel.sendMessage()
      } else { Task { await startVoiceRecording() } }
    } label: {
      sendButtonIcon
        .foregroundStyle(.white)
        .frame(width: 40, height: 40)
        // 텍스트 전송 가능할 때만 보라색이고, 음성 녹음 대기와 녹음 중에는 짙은 회색을 쓴다.
        .background((viewModel.canSend && !voiceRecorder.isRecording) ? .violet600 : .gray700)
        .clipShape(Circle())
    }
    .accessibilityLabel(voiceRecorder.isRecording ? "녹음 중지" : "메모 보내기 또는 음성 녹음")
  }

  @ViewBuilder
  private var sendButtonIcon: some View {
    if voiceRecorder.isRecording {
      Image(.stop)
        .resizable()
        .renderingMode(.template)
        .frame(width: 20, height: 20)
    } else if viewModel.canSend {
      Image(.arrowUp)
        .resizable()
        .renderingMode(.template)
        .frame(width: 20, height: 20)
    } else {
      Image(.sliders)
        .resizable()
        .renderingMode(.template)
        .frame(width: 20, height: 20)
    }
  }

  private func scrollToMessage(_ messageId: Note.ID?, with proxy: ScrollViewProxy) {
    guard let messageId else {
      return
    }

    withAnimation(.snappy(duration: 0.2)) {
      proxy.scrollTo(rowAnchorID(for: messageId), anchor: .bottom)
    }
  }

  /// 검색 결과에서 지정한 메시지가 로드되어 있으면 그 위치로 이동하고 잠깐 강조합니다.
  /// 이동했으면 true를 반환해 최신 메시지로 가는 기본 스크롤을 건너뛰게 합니다.
  private func scrollToInitialMessageIfNeeded(with proxy: ScrollViewProxy) -> Bool {
    guard
      let targetID = pendingInitialMessageID,
      viewModel.messages.contains(where: { $0.id == targetID })
    else {
      return false
    }

    pendingInitialMessageID = nil
    Task { @MainActor in
      // 지연 로딩되는 목록이 먼저 배치된 뒤 이동해야 먼 위치도 정확히 맞는다.
      try? await Task.sleep(for: .milliseconds(100))
      proxy.scrollTo(rowAnchorID(for: targetID), anchor: .center)
      // 스크롤이 자리를 잡은 뒤에 튀어야 눈에 보인다.
      try? await Task.sleep(for: .milliseconds(250))
      highlightedMessageID = targetID
      try? await Task.sleep(for: .milliseconds(180))
      highlightedMessageID = nil
    }
    return true
  }

  private func scrollToLatestMessage(with proxy: ScrollViewProxy, animated: Bool) {
    guard let messageId = viewModel.messages.last?.id else {
      return
    }

    if animated {
      withAnimation(.snappy(duration: 0.2)) {
        proxy.scrollTo(rowAnchorID(for: messageId), anchor: .bottom)
      }
    } else {
      proxy.scrollTo(rowAnchorID(for: messageId), anchor: .bottom)
    }
  }

  private func scrollToLatestMessageAfterKeyboardAppears(with proxy: ScrollViewProxy) {
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(250))
      scrollToLatestMessage(with: proxy, animated: true)
    }
  }

  /// 채팅 목록의 한 줄입니다. 일반 메시지와 같이 보낸 사진 묶음을 구분해서 그립니다.
  @ViewBuilder
  private func messageRow(for item: ChatMessageItem) -> some View {
    switch item {
    case let .single(note):
      selectableRow(ids: [note.id]) { singleBubble(for: note) }
    case let .photoGroup(notes):
      selectableRow(ids: notes.map(\.id)) { photoGroupBubble(for: notes) }
    }
  }

  /// 선택 가능한 줄입니다. 묶음은 안의 모든 사진이 함께 선택되고 해제됩니다.
  private func selectableRow<Content: View>(
    ids: [Note.ID],
    @ViewBuilder content: () -> Content
  ) -> some View {
    ChatSelectableRow(
      isSelectionActive: selection.isActive,
      isSelected: selection.isSelected(ids),
      onToggle: { selection.toggle(ids) },
      content: content
    )
    .id(ids[0])
  }

  private func singleBubble(for message: Note) -> some View {
    ChatMessageBubble(
      note: message,
      onDelete: { requestDelete(ids: [message.id]) },
      onShowFullText: { fullTextNote = message },
      linkPreview: viewModel.linkPreviews[message.id],
      voiceMemoState: viewModel.voiceMemoStates[message.id],
      fileDownloadState: viewModel.fileDownloadStates[message.id],
      fileTransferURL: viewModel.fileTransferURLs[message.id],
      fileSendFailed: viewModel.fileSendFailedIds.contains(message.id),
      onRetryTranscription: { Task { await viewModel.retryTranscription(for: message) } },
      onRetrySend: { Task { await viewModel.retrySend(for: message) } },
      onRetryFileDownload: { viewModel.retryFileDownload(for: message) },
      onRetryFileSend: { viewModel.retrySendFile(for: message) },
      onShowFile: { filePreviewNoteID = message.id },
      onShowPhoto: { photoPreviewNoteID = message.id },
      highlightQuery: isMessageSearchPresented ? viewModel.messageSearchText : nil,
      isHighlighted: highlightedMessageID == message.id,
      revealedTimeText: message.chatTimeText,
      timeRevealOffset: selection.isActive ? 0 : timeRevealOffset
    )
  }

  private func photoGroupBubble(for notes: [Note]) -> some View {
    ChatPhotoGroupBubble(
      notes: notes,
      onDelete: { requestDelete(ids: notes.map(\.id)) },
      onShowPhoto: { photoPreviewNoteID = $0.id },
      isHighlighted: notes.contains { $0.id == highlightedMessageID },
      revealedTimeText: notes.last?.chatTimeText,
      timeRevealOffset: selection.isActive ? 0 : timeRevealOffset
    )
  }

  /// 메시지 id가 같이 보낸 사진 묶음 안에 있으면 목록에서 그 줄을 가리키는 첫 사진의 id로 바꿉니다.
  private func rowAnchorID(for messageID: Note.ID) -> Note.ID {
    for section in viewModel.messageSections {
      for item in section.items {
        if case let .photoGroup(notes) = item, notes.contains(where: { $0.id == messageID }) {
          return item.id
        }
      }
    }
    return messageID
  }

  /// 길게 눌러 고른 메시지를 먼저 선택한 상태로 선택 모드를 시작합니다.
  private func requestDelete(ids: [Note.ID]) {
    isInputFocused = false
    selection.begin(with: ids)
  }

  private func requestSelectionDeletion() {
    let count = selection.count
    guard count > 0 else {
      return
    }

    deletionAlert = DestructiveConfirmationAlert(
      title: count > 1 ? "\(count)개의 노트를 삭제하시겠습니까?" : "이 노트를 삭제하시겠습니까?",
      message: "삭제한 노트는 복구할 수 없어요",
      acknowledgementText: nil
    ) {
      deleteSelectedMessages()
    }
  }

  private func deleteSelectedMessages() {
    let deletedCount = selection.count
    guard viewModel.deleteMessages(ids: selection.selectedIDs) else {
      toast = Toast(message: "메시지 삭제 실패했습니다", style: .failure)
      return
    }

    selection.end()
    toast = Toast(
      message: "메시지 \(deletedCount)개가 삭제되었습니다",
      style: .success,
      icon: "trash.fill"
    )
  }

  private func openCamera() async {
    switch await PermissionChecker.requestCameraAccess() {
    case .granted:
      isShowingCamera = true
    case .declinedInPrompt:
      break
    case .previouslyDenied:
      deniedPermission = .camera
    }
  }

  private func startVoiceRecording() async {
    switch await voiceRecorder.start() {
    case .started:
      // 녹음은 계속 진행하되, 음성 인식 권한이 없으면 텍스트 변환이 안 된다는 점을 안내한다.
      if await PermissionChecker.requestSpeechRecognitionAccess() == .previouslyDenied {
        deniedPermission = .speechRecognition
      }
    case .permissionDenied:
      deniedPermission = .microphone
    case .declinedInPrompt:
      break
    case .failed:
      toast = Toast(message: "녹음을 시작하지 못했습니다", style: .failure)
    }
  }

  private func deleteMessage(_ note: Note) -> Bool {
    viewModel.deleteMessage(id: note.id)
  }

  /// 다운로드 실패는 특정 버블에 계속 붙어있는 텍스트가 아니라 토스트로 한 번만 알려줍니다.
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

  /// 한 번에 고를 수 있는 앨범 사진 최대 개수입니다.
  private static let maxPhotoSelectionCount = 10

  /// 고른 순서대로 사진을 불러옵니다. 일부만 불러오지 못하면 가져온 사진만 확인 시트로 넘기고 안내합니다.
  /// 원본이 메모리에 쌓이지 않도록 한 장씩 읽자마자 백그라운드에서 줄여 전송용 데이터와 썸네일만 남깁니다.
  private func loadImages(from items: [PhotosPickerItem]) async {
    var photos: [PreparedPhoto] = []
    for item in items {
      guard let data = try? await item.loadTransferable(type: Data.self) else {
        continue
      }
      let prepared = await Task.detached(priority: .userInitiated) {
        PhotoPreparer.prepare(data)
      }.value
      if let prepared {
        photos.append(prepared)
      }
    }

    guard !photos.isEmpty else {
      toast = Toast(message: "사진을 불러오지 못했습니다.", style: .failure)
      return
    }

    if photos.count < items.count {
      toast = Toast(message: "일부 사진을 불러오지 못했습니다.", style: .failure)
    }
    pendingPhotoConfirmation = PhotoConfirmationRequest(photos: photos)
  }

  private func presentPendingCameraImage() {
    guard let image = pendingCameraImage else {
      return
    }

    pendingCameraImage = nil
    // 카메라 시트가 완전히 dismiss되기 전에 곧바로 다음 시트를 띄우면 SwiftUI가
    // presentationDetents를 무시하고 풀사이즈로 띄우는 경우가 있어, dismiss 애니메이션이
    // 끝난 뒤(약 0.35초) 확인 시트를 띄웁니다.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
      Task {
        // 카메라 사진도 메인 스레드를 막지 않게 백그라운드에서 줄인다.
        let prepared = await Task.detached(priority: .userInitiated) {
          image.jpegData(compressionQuality: 0.9).flatMap(PhotoPreparer.prepare)
        }.value
        if let prepared {
          pendingPhotoConfirmation = PhotoConfirmationRequest(photos: [prepared])
        } else {
          toast = Toast(message: "사진을 불러오지 못했습니다.", style: .failure)
        }
      }
    }
  }

  private func binding<Value>(
    _ keyPath: ReferenceWritableKeyPath<ChatViewModel, Value>
  ) -> Binding<Value> {
    Binding(
      get: { viewModel[keyPath: keyPath] },
      set: { viewModel[keyPath: keyPath] = $0 }
    )
  }

  private var persistenceErrorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.persistenceError != nil },
      set: { isPresented in
        if !isPresented {
          viewModel.clearPersistenceError()
        }
      }
    )
  }
}

private struct ChatDateDivider: View {
  let title: String

  var body: some View {
    Text(title)
      .typeStyle(.caption1)
      .foregroundStyle(.gray400)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
  }
}

/// ChatView의 body가 길어져 타입 체크가 느려지지 않도록 시트와 알럿 관련 modifier를 따로 묶었습니다.
private struct ChatPresentedModifier<FullText: View, FilePreview: View, PhotoPreview: View>: ViewModifier {
  let loadMessages: () async -> Void
  let persistenceError: Binding<Bool>
  let persistenceErrorMessage: String
  let clearPersistenceError: () -> Void
  let fullTextNote: Binding<Note?>
  let filePreviewNoteID: Binding<Note.ID?>
  let deletionAlert: Binding<DestructiveConfirmationAlert?>
  let deniedPermission: Binding<PermissionKind?>
  let photoPreviewNoteID: Binding<Note.ID?>
  let isShowingVoiceMemoPicker: Binding<Bool>
  let onPickVoiceMemo: (URL) -> Void
  let fullTextView: (Note) -> FullText
  let filePreviewView: (Note.ID) -> FilePreview
  let photoPreviewView: (Note.ID) -> PhotoPreview

  func body(content: Content) -> some View {
    content
      .task { await loadMessages() }
      .alert("오류", isPresented: persistenceError) {
        Button("확인", action: clearPersistenceError)
      } message: {
        Text(persistenceErrorMessage)
      }
      .sheet(item: fullTextNote) { note in
        fullTextView(note)
      }
      .navigationDestination(item: filePreviewNoteID) { noteID in
        filePreviewView(noteID)
      }
      .destructiveConfirmationAlert(item: deletionAlert)
      .permissionDeniedAlert(deniedPermission)
      .navigationDestination(item: photoPreviewNoteID) { noteID in
        photoPreviewView(noteID)
      }
      .sheet(isPresented: isShowingVoiceMemoPicker) {
        FileDocumentPicker(contentTypes: [.audio], onPick: onPickVoiceMemo)
      }
  }
}

#Preview {
  NavigationStack {
    ChatView(
      contact: Contact(
        name: "Sample User",
        role: "Product Designer",
        company: "@syno"
      ),
      repository: PreviewRepositories.note,
      imageAnalyzer: PreviewRepositories.noteImageAnalyzer,
      imageAnalysisRepository: PreviewRepositories.noteImageAnalysis,
      linkPreviewFetcher: PreviewRepositories.linkPreviewFetcher,
      linkPreviewRepository: PreviewRepositories.noteLinkPreview,
      labelTranslator: PreviewRepositories.labelTranslator,
      voiceTranscriber: PreviewRepositories.noteVoiceTranscriber,
      voiceTranscriptRepository: PreviewRepositories.noteVoiceTranscript
    )
  }
}
