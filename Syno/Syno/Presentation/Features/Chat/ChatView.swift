//
//  ChatView.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// 연락처별로 나에게 보내는 형식의 기록을 남기는 채팅 화면입니다.
struct ChatView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var storedNotes: [StoredNote]
  @State private var messageText = ""
  @State private var selectedPhotoItem: PhotosPickerItem?
  @FocusState private var isInputFocused: Bool

  let contact: Contact

  init(contact: Contact) {
    self.contact = contact

    let contactId: UUID? = contact.id
    _storedNotes = Query(
      filter: #Predicate<StoredNote> { $0.contactId == contactId },
      sort: \StoredNote.createdAt
    )
  }

  private var messages: [Note] {
    storedNotes.map(\.note)
  }

  private var canSend: Bool {
    !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    VStack(spacing: 0) {
      messagesScrollView
      messageInputBar
    }
    .background(Color.gray50)
    .navigationTitle(contact.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {} label: {
          Image(systemName: "magnifyingglass")
        }
        .accessibilityLabel("Search Notes")
      }
    }
    .tint(.gray950)
    .scrollDismissesKeyboard(.interactively)
    .onChange(of: selectedPhotoItem) { _, selectedPhotoItem in
      Task {
        await sendImage(from: selectedPhotoItem)
      }
    }
  }

  private var messagesScrollView: some View {
    ScrollViewReader { proxy in
      ScrollView {
        if messages.isEmpty {
          ChatEmptyStateView()
        } else {
          LazyVStack(alignment: .trailing, spacing: 12) {
            ForEach(messages) { message in
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
      .onChange(of: messages.last?.id) { _, messageId in
        scrollToMessage(messageId, with: proxy)
      }
      .onChange(of: isInputFocused) { _, isFocused in
        if isFocused {
          scrollToLatestMessageAfterKeyboardAppears(with: proxy)
        }
      }
    }
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

      TextField("메모 입력", text: $messageText, axis: .vertical)
        .typeStyle(.body)
        .lineLimit(1...4)
        .focused($isInputFocused)
        .submitLabel(.send)
        .onSubmit(sendMessage)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.gray100)
        .clipShape(Capsule())

      Button(action: sendMessage) {
        Image(systemName: "arrow.up")
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
          .background(canSend ? .violet500 : .gray300)
          .clipShape(Circle())
      }
      .disabled(!canSend)
      .accessibilityLabel("Send Note")
    }
    .padding(.horizontal, 14)
    .padding(.top, 10)
    .padding(.bottom, 10)
    .background(Color.gray50)
  }

  private func sendMessage() {
    let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedText.isEmpty else {
      return
    }

    let note = Note(
      contactId: contact.id,
      contactName: contact.name,
      content: trimmedText,
      profileImageData: contact.profileImageData
    )

    modelContext.insert(StoredNote(note: note))
    try? modelContext.save()
    messageText = ""
  }

  private func sendImage(from item: PhotosPickerItem?) async {
    guard
      let item,
      let rawImageData = try? await item.loadTransferable(type: Data.self),
      let imageData = Self.compressedImageData(from: rawImageData)
    else {
      return
    }

    let note = Note(
      contactId: contact.id,
      contactName: contact.name,
      content: "사진",
      imageData: imageData,
      profileImageData: contact.profileImageData
    )

    modelContext.insert(StoredNote(note: note))
    try? modelContext.save()
    selectedPhotoItem = nil
  }

  private static func compressedImageData(from data: Data, maxDimension: CGFloat = 1600) -> Data? {
    guard let image = UIImage(data: data) else {
      return nil
    }

    let scale = min(1, maxDimension / max(image.size.width, image.size.height))
    let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

    let resizedImage = UIGraphicsImageRenderer(size: targetSize).image { _ in
      image.draw(in: CGRect(origin: .zero, size: targetSize))
    }

    return resizedImage.jpegData(compressionQuality: 0.8)
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
    guard let messageId = messages.last?.id else {
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
}

#Preview {
  NavigationStack {
    ChatView(
      contact: Contact(
        name: "Sample User",
        role: "Product Designer",
        company: "@syno"
      )
    )
  }
  .modelContainer(for: StoredNote.self, inMemory: true)
}
