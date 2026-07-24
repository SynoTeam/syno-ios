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
  @State private var isMessageSearchPresented = false
  @FocusState private var isInputFocused: Bool
  @FocusState private var isSearchFocused: Bool

  init(
    contact: Contact,
    repository: any NoteRepository,
    imageAnalyzer: any NoteImageAnalyzing,
    imageAnalysisRepository: any NoteImageAnalysisRepository
  ) {
    _viewModel = State(
      initialValue: ChatViewModel(
        contact: contact,
        repository: repository,
        imageAnalyzer: imageAnalyzer,
        imageAnalysisRepository: imageAnalysisRepository
      )
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      messagesScrollView
      messageInputBar
    }
    .background(Color.gray50)
    .navigationTitle(viewModel.contact.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          toggleMessageSearch()
        } label: {
          Image(systemName: isMessageSearchPresented ? "xmark" : "magnifyingglass")
        }
        .accessibilityLabel(isMessageSearchPresented ? "메시지 검색 닫기" : "메시지 검색")
      }
    }
    .tint(.gray950)
    .scrollDismissesKeyboard(.interactively)
    .onChange(of: selectedPhotoItem) { _, selectedPhotoItem in
      Task {
        await viewModel.sendImage(from: selectedPhotoItem)
        self.selectedPhotoItem = nil
      }
    }
    .onAppear(perform: viewModel.loadMessages)
    .alert(
      "오류",
      isPresented: persistenceErrorBinding
    ) {
      Button("확인", action: viewModel.clearPersistenceError)
    } message: {
      Text(viewModel.persistenceError ?? "")
    }
  }

  private var messagesScrollView: some View {
    ScrollViewReader { proxy in
      VStack(spacing: 0) {
        if isMessageSearchPresented {
          messageSearchPanel { messageId in
            scrollToMessage(messageId, with: proxy)
          }
        }

        ScrollView {
          if viewModel.messages.isEmpty {
            ChatEmptyStateView()
          } else {
            LazyVStack(alignment: .trailing, spacing: 12) {
              ForEach(viewModel.messages) { message in
                ChatMessageBubble(note: message)
                  .id(message.id)
              }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
          }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
          scrollToLatestMessage(with: proxy, animated: false)
        }
        .onChange(of: viewModel.messages.last?.id) { _, messageId in
          scrollToMessage(messageId, with: proxy)
        }
        .onChange(of: isInputFocused) { _, isFocused in
          if isFocused {
            scrollToLatestMessageAfterKeyboardAppears(with: proxy)
          }
        }
      }
    }
  }

  private func messageSearchPanel(
    onSelect: @escaping (Note.ID) -> Void
  ) -> some View {
    VStack(spacing: 8) {
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

      if !viewModel.messageSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        if viewModel.messageSearchResults.isEmpty {
          Text("일치하는 메시지가 없습니다.")
            .typeStyle(.footnote)
            .foregroundStyle(.gray500)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        } else {
          ScrollView {
            LazyVStack(spacing: 0) {
              ForEach(viewModel.messageSearchResults) { message in
                Button {
                  onSelect(message.id)
                  isSearchFocused = false
                } label: {
                  HStack {
                    Text(message.content)
                      .typeStyle(.footnote)
                      .foregroundStyle(.gray900)
                      .lineLimit(1)

                    Spacer()

                    Text(message.timeText)
                      .typeStyle(.caption1)
                      .foregroundStyle(.gray400)
                  }
                  .padding(.horizontal, 12)
                  .frame(minHeight: 42)
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
              }
            }
          }
          .frame(maxHeight: 168)
        }
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(.white)
  }

  private var messageInputBar: some View {
    HStack(spacing: 10) {
      PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
        Image(systemName: "plus")
          .font(.system(size: 22, weight: .regular))
          .foregroundStyle(.gray700)
          .frame(width: 44, height: 44)
          .background(.gray100)
          .clipShape(Circle())
      }
      .accessibilityLabel("Add Photo")

      TextField("메모 입력", text: binding(\.messageText), axis: .vertical)
        .typeStyle(.body)
        .lineLimit(1...4)
        .focused($isInputFocused)
        .submitLabel(.send)
        .onSubmit(viewModel.sendMessage)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.gray100)
        .clipShape(Capsule())

      Button(action: viewModel.sendMessage) {
        Image(systemName: "arrow.up")
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
          .background(viewModel.canSend ? .violet500 : .gray300)
          .clipShape(Circle())
      }
      .disabled(!viewModel.canSend)
      .accessibilityLabel("Send Note")
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
    isInputFocused = false

    if isMessageSearchPresented {
      isSearchFocused = true
    } else {
      isSearchFocused = false
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
      imageAnalysisRepository: PreviewRepositories.noteImageAnalysis
    )
  }
}
