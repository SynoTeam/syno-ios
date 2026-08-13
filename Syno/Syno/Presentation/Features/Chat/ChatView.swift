//
//  ChatView.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import PhotosUI
import SwiftUI

/// 연락처별로 나에게 보내는 형식의 기록을 남기는 채팅 화면입니다.
struct ChatView: View {
  @State private var viewModel: ChatViewModel
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var isShowingPhotosPicker = false
  @State private var isShowingCamera = false
  @State private var isShowingFilePicker = false
  @State private var isMessageSearchPresented = false
  @State private var currentMatchIndex = 0
  @State private var isShowingArchive = false
  @State private var notePendingDeletion: Note?
  @State private var toast: Toast?
  @State private var fullTextNote: Note?
  @State private var filePreviewNoteID: Note.ID?
  @State private var toastedFailedFileDownloadIds: Set<Note.ID> = []
  @State private var voiceRecorder = VoiceRecorder()
  @FocusState private var isInputFocused: Bool
  @FocusState private var isSearchFocused: Bool

  init(
    contact: Contact,
    repository: any NoteRepository,
    imageAnalyzer: any NoteImageAnalyzing,
    imageAnalysisRepository: any NoteImageAnalysisRepository,
    linkPreviewFetcher: any NoteLinkPreviewFetching = NoopNoteLinkPreviewFetcher(),
    linkPreviewRepository: any NoteLinkPreviewRepository = NoopNoteLinkPreviewRepository(),
    labelTranslator: any LabelTranslating,
    voiceTranscriber: any NoteVoiceTranscribing,
    voiceTranscriptRepository: any NoteVoiceTranscriptRepository
  ) {
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
        voiceTranscriptRepository: voiceTranscriptRepository
      )
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      messagesScrollView
      messageInputBar
    }
    .background(Color.gray50)
    .toast(item: $toast)
    .onChange(of: viewModel.fileDownloadStates) { _, newStates in
      handleFileDownloadStateChange(newStates)
    }
    .navigationTitle(viewModel.contact.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          toggleMessageSearch()
        } label: {
          Image(systemName: isMessageSearchPresented ? "xmark" : "magnifyingglass")
        }
        .accessibilityLabel(isMessageSearchPresented ? "메시지 검색 닫기" : "메시지 검색")

        Button {
          isShowingArchive = true
        } label: {
          Image(systemName: "line.3.horizontal")
        }
        .accessibilityLabel("아카이브")
      }
    }
    .navigationDestination(isPresented: $isShowingArchive) {
      ArchiveView(viewModel: viewModel)
    }
    .tint(.gray950)
    .scrollDismissesKeyboard(.interactively)
    .onChange(of: selectedPhotoItem) { _, selectedPhotoItem in
      Task {
        await viewModel.sendImage(from: selectedPhotoItem)
        self.selectedPhotoItem = nil
      }
    }
    .photosPicker(isPresented: $isShowingPhotosPicker, selection: $selectedPhotoItem, matching: .images)
    .sheet(isPresented: $isShowingCamera) {
      CameraPickerView { image in
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        Task { await viewModel.sendImageData(data) }
      }
      .ignoresSafeArea()
    }
    .sheet(isPresented: $isShowingFilePicker) {
      FileDocumentPicker { url in
        Task { await viewModel.sendFile(url: url) }
      }
    }
    .task {
      await viewModel.loadMessages()
    }
    .alert(
      "오류",
      isPresented: persistenceErrorBinding
    ) {
      Button("확인", action: viewModel.clearPersistenceError)
    } message: {
      Text(viewModel.persistenceError ?? "")
    }
    .sheet(item: $fullTextNote) { note in
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
    .navigationDestination(item: $filePreviewNoteID) { noteID in
      FilePreviewView(viewModel: viewModel, noteID: noteID)
    }
    .navigationDestination(item: $notePendingDeletion) { note in
      ChatNoteDeletionView(
        viewModel: viewModel,
        initiallySelectedNoteID: note.id
      ) { deletedCount in
        notePendingDeletion = nil
        toast = Toast(
          message: "메시지 \(deletedCount)개가 삭제되었습니다",
          style: .success,
          icon: "trash.fill"
        )
      }
    }
  }

  private var messagesScrollView: some View {
    ScrollViewReader { proxy in
      VStack(spacing: 0) {
        if isMessageSearchPresented {
          messageSearchBar
        }

        ScrollView {
          if viewModel.messages.isEmpty && viewModel.pendingMessages.isEmpty {
            ChatEmptyStateView()
          } else {
            LazyVStack(alignment: .trailing, spacing: 12) {
              ForEach(viewModel.messageSections) { section in
                ChatDateDivider(title: section.title)

                ForEach(section.messages) { message in
                  ChatMessageBubble(
                    note: message,
                    onDelete: { requestDelete(message) },
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
                    highlightQuery: isMessageSearchPresented ? viewModel.messageSearchText : nil
                  )
                    .id(message.id)
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
        .overlay(alignment: .bottom) {
          if isMessageSearchPresented, !viewModel.messageSearchResults.isEmpty {
            matchNavigator(with: proxy)
          }
        }
        .onAppear {
          scrollToLatestMessage(with: proxy, animated: false)
        }
        .onChange(of: viewModel.messages.last?.id) { _, messageId in
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

  private var messageSearchBar: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.gray400)

      TextField("이 채팅에서 검색", text: binding(\.messageSearchText))
        .typeStyle(.body)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .focused($isSearchFocused)

      if !viewModel.messageSearchText.isEmpty {
        Button {
          viewModel.messageSearchText = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.gray400)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("검색어 지우기")
      }
    }
    .padding(.horizontal, 14)
    .frame(height: 44)
    .background(.gray100)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(.white)
  }

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

  private var messageInputBar: some View {
    HStack(alignment: .bottom, spacing: 10) {
      Menu {
        Button {
          isShowingCamera = true
        } label: {
          Label("카메라", systemImage: "camera")
        }

        Button {
          isShowingPhotosPicker = true
        } label: {
          Label("앨범", systemImage: "photo")
        }

        Button {
          isShowingFilePicker = true
        } label: {
          Label("파일", systemImage: "folder")
        }
      } label: {
        Image(systemName: "plus")
          .font(.system(size: 22, weight: .regular))
          .foregroundStyle(.gray700)
          .frame(width: 44, height: 44)
          .background(.gray100)
          .clipShape(Circle())
      }
      .accessibilityLabel("메모 추가")

      if voiceRecorder.isRecording {
        HStack(spacing: 8) {
          HStack(spacing: 1.5) {
            ForEach(voiceRecorder.levels.indices, id: \.self) { index in
              Capsule().fill(Color.violet500).frame(width: 2, height: max(8, voiceRecorder.levels[index] * 32))
                .animation(.easeInOut(duration: 0.15), value: voiceRecorder.levels[index])
            }
          }
          .clipped()
          .animation(.easeInOut(duration: 0.1), value: voiceRecorder.levels.count)
          Spacer(minLength: 8)
          Text(String(format: "%d:%02d", Int(voiceRecorder.duration) / 60, Int(voiceRecorder.duration) % 60)).typeStyle(.footnote)
        }
          .padding(.horizontal, 16).frame(maxWidth: .infinity).frame(height: 44).background(.gray100).clipShape(Capsule())
      } else {
        TextField("메모 입력", text: binding(\.messageText), axis: .vertical)
        .typeStyle(.body)
        .lineLimit(1...6)
        .focused($isInputFocused)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.gray100)
          .clipShape(Capsule())
      }

      Button {
        if voiceRecorder.isRecording, let memo = voiceRecorder.stop() { Task { await viewModel.sendVoiceMemo(audioData: memo.data, duration: memo.duration, waveform: memo.waveform) } }
        else if viewModel.canSend { viewModel.sendMessage() }
        else { Task { _ = await voiceRecorder.start() } }
      } label: {
        Image(systemName: voiceRecorder.isRecording ? "stop.fill" : (viewModel.canSend ? "arrow.up" : "mic.fill"))
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
          .background((viewModel.canSend || voiceRecorder.isRecording) ? .violet500 : .gray300)
          .clipShape(Circle())
      }
      .accessibilityLabel(voiceRecorder.isRecording ? "녹음 중지" : "메모 보내기 또는 음성 녹음")
    }
    .padding(.horizontal, 14)
    .padding(.top, 10)
    .padding(.bottom, 10)
    .background(Color.gray50)
  }

  private func scrollToMessage(_ messageId: Note.ID?, with proxy: ScrollViewProxy) {
    guard let messageId else {
      return
    }

    withAnimation(.snappy(duration: 0.2)) {
      proxy.scrollTo(messageId, anchor: .bottom)
    }
  }

  private func scrollToLatestMessage(with proxy: ScrollViewProxy, animated: Bool) {
    guard let messageId = viewModel.messages.last?.id else {
      return
    }

    if animated {
      withAnimation(.snappy(duration: 0.2)) {
        proxy.scrollTo(messageId, anchor: .bottom)
      }
    } else {
      proxy.scrollTo(messageId, anchor: .bottom)
    }
  }

  private func scrollToLatestMessageAfterKeyboardAppears(with proxy: ScrollViewProxy) {
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(250))
      scrollToLatestMessage(with: proxy, animated: true)
    }
  }

  private func toggleMessageSearch() {
    isMessageSearchPresented.toggle()
    viewModel.messageSearchText = ""
    currentMatchIndex = 0
    isInputFocused = false

    if isMessageSearchPresented {
      isSearchFocused = true
    } else {
      isSearchFocused = false
    }
  }

  private func requestDelete(_ note: Note) {
    notePendingDeletion = note
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
    HStack(spacing: 10) {
      Rectangle()
        .fill(Color.gray200)
        .frame(height: 1)

      Text(title)
        .typeStyle(.caption1)
        .foregroundStyle(.gray400)
        .fixedSize(horizontal: true, vertical: false)

      Rectangle()
        .fill(Color.gray200)
        .frame(height: 1)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
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
