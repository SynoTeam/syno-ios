//
//  ShareExtensionView.swift
//  SynoShareExtension
//

import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers

enum SharedContent {
  case text(String)
  case url(URL)
  case image(Data)
}

struct ShareExtensionView: View {
  let extensionItems: [NSExtensionItem]
  let onFinish: () -> Void
  let onCancel: () -> Void

  @State private var modelContainer: ModelContainer?
  @State private var sharedContent: SharedContent?
  @State private var isLoadingContent = true
  @State private var contacts: [StoredContact] = []
  @State private var searchText = ""
  @State private var selectedContactID: UUID?
  @State private var isSaving = false
  @State private var didSave = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      Group {
        if didSave {
          successView
        } else if isLoadingContent {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          pickerView
        }
      }
      .navigationTitle("공유하기")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("취소", action: onCancel)
        }
        if !didSave {
          ToolbarItem(placement: .confirmationAction) {
            Button("저장", action: save)
              .disabled(selectedContactID == nil || isSaving)
          }
        }
      }
    }
    .task {
      sharedContent = await Self.loadSharedContent(from: extensionItems)
      isLoadingContent = false
      openContainerAndLoadContacts()
    }
  }

  private var pickerView: some View {
    VStack(spacing: 0) {
      previewSection

      if let errorMessage {
        Text(errorMessage)
          .font(.footnote)
          .foregroundStyle(.red)
          .padding(.horizontal, 16)
          .padding(.top, 8)
      }

      List(filteredContacts, id: \.id) { contact in
        Button {
          selectedContactID = contact.id
        } label: {
          HStack(spacing: 12) {
            contactAvatar(contact)

            VStack(alignment: .leading, spacing: 2) {
              Text(contact.name)
                .foregroundStyle(.primary)
              if !contact.group.isEmpty {
                Text(contact.group)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }

            Spacer()

            Image(systemName: selectedContactID == contact.id ? "checkmark.circle.fill" : "circle")
              .foregroundStyle(selectedContactID == contact.id ? Color.accentColor : Color.secondary.opacity(0.4))
          }
        }
        .buttonStyle(.plain)
      }
      .listStyle(.plain)
      .searchable(text: $searchText, prompt: "연락처 검색")
    }
  }

  private var previewSection: some View {
    VStack(alignment: .leading, spacing: 4) {
      switch sharedContent {
      case let .text(text):
        Text(text)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(3)
      case let .url(url):
        Text(url.absoluteString)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      case .image:
        Text("사진")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      case nil:
        Text("공유할 내용을 확인할 수 없습니다.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
  }

  private var successView: some View {
    VStack(spacing: 12) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 44))
        .foregroundStyle(.green)
      Text("노트가 저장되었습니다")
        .font(.headline)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .task {
      try? await Task.sleep(for: .milliseconds(700))
      onFinish()
    }
  }

  private var filteredContacts: [StoredContact] {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return contacts
    }
    return contacts.filter { $0.name.localizedStandardContains(trimmed) }
  }

  @ViewBuilder
  private func contactAvatar(_ contact: StoredContact) -> some View {
    if let data = contact.profileImageData, let uiImage = UIImage(data: data) {
      Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    } else {
      Circle()
        .fill(Color.secondary.opacity(0.2))
        .frame(width: 40, height: 40)
    }
  }

  private func openContainerAndLoadContacts() {
    do {
      let schema = Schema([StoredContact.self, StoredNote.self])
      let configuration = ModelConfiguration(schema: schema, url: SharedAppGroup.storeURL)
      let container = try ModelContainer(for: schema, configurations: configuration)
      modelContainer = container
      let descriptor = FetchDescriptor<StoredContact>(sortBy: [SortDescriptor(\.name)])
      contacts = try container.mainContext.fetch(descriptor).filter { !$0.isMe }
    } catch {
      errorMessage = "연락처를 불러오지 못했습니다."
    }
  }

  private func save() {
    guard
      let modelContainer,
      let selectedContactID,
      let contact = contacts.first(where: { $0.id == selectedContactID })
    else {
      return
    }

    isSaving = true

    let note: StoredNote
    switch sharedContent {
    case let .text(text):
      note = StoredNote(
        id: UUID(),
        contactId: contact.id,
        contactName: contact.name,
        content: text,
        imageData: nil,
        profileImageData: contact.profileImageData,
        isFavorite: false
      )
    case let .url(url):
      note = StoredNote(
        id: UUID(),
        contactId: contact.id,
        contactName: contact.name,
        content: url.absoluteString,
        imageData: nil,
        profileImageData: contact.profileImageData,
        isFavorite: false
      )
    case let .image(data):
      note = StoredNote(
        id: UUID(),
        contactId: contact.id,
        contactName: contact.name,
        content: "사진",
        imageData: data,
        profileImageData: contact.profileImageData,
        isFavorite: false
      )
    case nil:
      isSaving = false
      errorMessage = "공유할 내용이 없습니다."
      return
    }

    modelContainer.mainContext.insert(note)

    do {
      try modelContainer.mainContext.save()
      didSave = true
    } catch {
      errorMessage = "저장에 실패했습니다."
    }
    isSaving = false
  }

  private static func loadSharedContent(from items: [NSExtensionItem]) async -> SharedContent? {
    guard let attachment = items.first?.attachments?.first else {
      return nil
    }

    if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
      if let data = await loadData(from: attachment, typeIdentifier: UTType.image.identifier) {
        return .image(data)
      }
    }

    if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
      if let item = await loadItem(from: attachment, typeIdentifier: UTType.url.identifier),
         let url = item as? URL {
        return .url(url)
      }
    }

    if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
      if let item = await loadItem(from: attachment, typeIdentifier: UTType.plainText.identifier),
         let text = item as? String {
        return .text(text)
      }
    }

    return nil
  }

  private static func loadItem(from provider: NSItemProvider, typeIdentifier: String) async -> NSSecureCoding? {
    await withCheckedContinuation { continuation in
      provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
        continuation.resume(returning: item)
      }
    }
  }

  private static func loadData(from provider: NSItemProvider, typeIdentifier: String) async -> Data? {
    guard let item = await loadItem(from: provider, typeIdentifier: typeIdentifier) else {
      return nil
    }

    if let data = item as? Data {
      return data
    }
    if let url = item as? URL, let data = try? Data(contentsOf: url) {
      return data
    }
    if let image = item as? UIImage {
      return image.jpegData(compressionQuality: 0.9)
    }
    return nil
  }
}
