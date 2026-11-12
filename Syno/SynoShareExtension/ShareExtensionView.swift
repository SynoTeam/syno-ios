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
  @State private var candidates: [ShareContactCandidate] = []
  @State private var latestNotes: [UUID: ShareLatestNote] = [:]
  @State private var groupNames: [String] = []
  /// 고른 그룹 칩입니다. nil이면 전체입니다.
  @State private var selectedGroup: String?
  @State private var searchText = ""
  @State private var selectedContactID: UUID?
  @State private var isSaving = false
  @State private var didSave = false
  @State private var errorMessage: String?

  var body: some View {
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
    .background(Color.gray50)
    .task {
      sharedContent = await Self.loadSharedContent(from: extensionItems)
      isLoadingContent = false
      openContainerAndLoadContacts()
    }
  }

  private var pickerView: some View {
    VStack(spacing: 0) {
      AddContactSheetHeader(
        title: "공유하기",
        onCancel: onCancel,
        isApplyEnabled: visibleSelectedContactID != nil && !isSaving,
        onApply: save
      )

      groupChips

      if let errorMessage {
        Text(errorMessage)
          .typeStyle(.footnote)
          .foregroundStyle(.red)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
          .padding(.bottom, 8)
      }

      ScrollView {
        LazyVStack(spacing: 8) {
          if rows.isEmpty {
            Text(candidates.isEmpty ? "연락처가 없습니다." : "검색결과가 없습니다.")
              .typeStyle(.body)
              .foregroundStyle(.gray400)
              .frame(maxWidth: .infinity)
              .frame(height: 180)
          } else {
            ForEach(rows) { row in
              ShareContactRowView(
                row: row,
                isSelected: selectedContactID == row.id,
                onSelect: { selectedContactID = row.id }
              )
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 88)
      }
      .scrollDismissesKeyboard(.immediately)
      .safeAreaInset(edge: .bottom, spacing: 0) {
        searchField
      }
    }
    .padding(.top, 16)
  }

  private var groupChips: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        NoteFilterChip(title: "All", isSelected: selectedGroup == nil) {
          selectedGroup = nil
        }
        ForEach(groupNames, id: \.self) { name in
          NoteFilterChip(title: name, isSelected: selectedGroup == name) {
            selectedGroup = name
          }
        }
      }
      .padding(.horizontal, 16)
    }
    .padding(.bottom, 8)
  }

  private var searchField: some View {
    HStack(spacing: 8) {
      Image(.search)
        .resizable()
        .renderingMode(.template)
        .frame(width: 20, height: 20)
        .foregroundStyle(.gray500)

      TextField("연락처 검색", text: $searchText)
        .typeStyle(.body)
        .foregroundStyle(.gray950)
        .autocorrectionDisabled()

      Button {
        searchText = ""
      } label: {
        Image(.xCircle)
          .resizable()
          .renderingMode(.template)
          .frame(width: 20, height: 20)
          .foregroundStyle(.gray400)
      }
      .buttonStyle(.plain)
      .disabled(searchText.isEmpty)
      .opacity(searchText.isEmpty ? 0.4 : 1)
      .accessibilityLabel("검색어 지우기")
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .glassEffect(.regular, in: .capsule)
    .padding(.horizontal, 16)
    .padding(.bottom, 8)
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

  private var rows: [ShareContactRow] {
    ShareContactList.rows(
      from: candidates,
      latestNotes: latestNotes,
      group: selectedGroup,
      searchText: searchText
    )
  }

  /// 지금 목록에 보이는 경우에만 선택된 연락처입니다.
  private var visibleSelectedContactID: UUID? {
    ShareContactList.visibleSelection(selectedContactID, in: rows)
  }

  private func openContainerAndLoadContacts() {
    do {
      // 모델 일부만으로 열면 Core Data가 빠진 모델의 테이블을 지우므로 앱과 같은 전체 목록으로 연다 (#124).
      let schema = SynoSchema.schema
      let configuration = ModelConfiguration(schema: schema, url: SharedAppGroup.storeURL)
      let container = try ModelContainer(for: schema, configurations: configuration)
      modelContainer = container
      let context = container.mainContext

      candidates = try context.fetch(FetchDescriptor<StoredContact>()).map {
        ShareContactCandidate(
          id: $0.id,
          name: $0.name,
          group: $0.group,
          isMe: $0.isMe,
          profileImageData: $0.profileImageData
        )
      }

      groupNames = ShareContactList.groupNames(
        try context.fetch(FetchDescriptor<StoredGroup>()).map { (name: $0.name, sortIndex: $0.sortIndex) }
      )

      // 확장은 메모리 제한이 작으므로 사진·음성·파일 데이터는 읽지 않고 필요한 속성만 가져온다.
      var noteDescriptor = FetchDescriptor<StoredNote>()
      noteDescriptor.propertiesToFetch = [\.contactId, \.content, \.createdAt]
      latestNotes = ShareContactList.latestNotes(
        try context.fetch(noteDescriptor).map {
          (contactId: $0.contactId, content: $0.content, createdAt: $0.createdAt)
        }
      )
    } catch {
      errorMessage = "연락처를 불러오지 못했습니다."
    }
  }

  private func save() {
    guard
      let modelContainer,
      // 그룹 칩이나 검색으로 숨겨진 연락처에는 저장하지 않는다.
      let selectedContactID = visibleSelectedContactID,
      let contact = candidates.first(where: { $0.id == selectedContactID })
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
