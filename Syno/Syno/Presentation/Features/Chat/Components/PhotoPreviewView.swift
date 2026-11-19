import Photos
import SwiftUI
import UIKit

/// 채팅의 사진을 크게 보여주는 미리보기 화면입니다.
/// 같은 채팅의 사진들을 넘겨 보거나 썸네일로 고를 수 있고, 아래 버튼으로 저장, 공유, 복사, 삭제를 합니다.
struct PhotoPreviewView: View {
  @Environment(\.dismiss) private var dismiss

  let viewModel: ChatViewModel

  @State private var selectedID: Note.ID
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var deniedPermission: PermissionKind?
  @State private var toast: Toast?
  /// 저장이 끝나기 전에 다시 저장해 같은 사진이 두 번 들어가지 않도록 저장 중에는 저장 버튼을 막습니다.
  @State private var isSaving = false

  init(viewModel: ChatViewModel, noteID: Note.ID) {
    self.viewModel = viewModel
    _selectedID = State(initialValue: noteID)
  }

  /// 채팅에 있는 모든 사진입니다. 삭제되면 목록에서 바로 빠집니다.
  private var photos: [Note] {
    viewModel.messages.filter { $0.imageData != nil }
  }

  /// 지금 보고 있는 사진과 같이 보낸 사진들입니다. 혼자 보낸 사진이면 비어 있습니다.
  private var selectedGroupPhotos: [Note] {
    guard
      let groupId = photos.first(where: { $0.id == selectedID })?.photoGroupId
    else {
      return []
    }
    let group = photos.filter { $0.photoGroupId == groupId }
    return group.count > 1 ? group : []
  }

  private var selectedImage: UIImage? {
    photos.first { $0.id == selectedID }
      .flatMap(\.imageData)
      .flatMap { UIImage(data: $0) }
  }

  var body: some View {
    VStack(spacing: 0) {
      pager

      VStack(spacing: 20) {
        if !selectedGroupPhotos.isEmpty {
          thumbnails
        }
        actionBar
      }
      .padding(.top, 20)
      .padding(.bottom, 16)
    }
    .animation(.snappy, value: selectedGroupPhotos.isEmpty)
    .background(Color.gray50)
    .navigationBarTitleDisplayMode(.inline)
    .synoBackButton()
    .toolbar(.hidden, for: .tabBar)
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .permissionDeniedAlert($deniedPermission)
    .toast(item: $toast)
  }

  private var pager: some View {
    TabView(selection: $selectedID) {
      ForEach(photos) { note in
        if let data = note.imageData, let image = UIImage(data: data) {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tag(note.id)
        }
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
  }

  private var thumbnails: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(selectedGroupPhotos) { note in
            thumbnail(for: note)
          }
        }
        .padding(.horizontal, 16)
      }
      // 썸네일이 적을 때는 가운데에 모이고, 많으면 좌우로 스크롤된다.
      .defaultScrollAnchor(.center)
      .scrollBounceBehavior(.basedOnSize)
      .onChange(of: selectedID) { _, id in
        withAnimation(.snappy) { proxy.scrollTo(id, anchor: .center) }
      }
    }
    .frame(height: 56)
  }

  private func thumbnail(for note: Note) -> some View {
    let isSelected = note.id == selectedID

    return Button {
      withAnimation(.snappy) { selectedID = note.id }
    } label: {
      if let data = note.imageData, let image = UIImage(data: data) {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 40, height: 56)
          .clipShape(RoundedRectangle(cornerRadius: 10))
          .opacity(isSelected ? 1 : 0.5)
      }
    }
    .buttonStyle(.plain)
    .id(note.id)
    .accessibilityLabel(isSelected ? "선택된 사진" : "사진")
  }

  private var actionBar: some View {
    PreviewActionBar {
      saveButton

      shareButton

      Button(action: copyToPasteboard) {
        PreviewActionIcon(.copy)
      }
      .buttonStyle(.plain)
      .disabled(selectedImage == nil)
      .accessibilityLabel("복사하기")

      Button(action: requestDeleteConfirmation) {
        PreviewActionIcon(.trash)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("삭제")
    }
  }

  /// 혼자 보낸 사진은 바로 저장하고, 묶음 사진은 한 장 저장과 전체 저장 중에 고르게 합니다.
  @ViewBuilder private var saveButton: some View {
    if selectedGroupPhotos.isEmpty {
      Button {
        Task { await save(selectedPhotoNotes, scope: .single) }
      } label: {
        PreviewActionIcon(.download)
      }
      .buttonStyle(.plain)
      .disabled(selectedImage == nil || isSaving)
      .accessibilityLabel("사진 저장")
    } else {
      Menu {
        Button("선택 사진만") {
          Task { await save(selectedPhotoNotes, scope: .selected) }
        }
        Button("전체 사진") {
          Task { await save(selectedGroupPhotos, scope: .all) }
        }
      } label: {
        PreviewActionIcon(.download)
      }
      // 바가 화면 아래에 있어 메뉴가 위로 열려도 적은 순서대로(선택 사진만 → 전체 사진) 보이게 한다.
      .menuOrder(.fixed)
      .disabled(isSaving)
      .buttonStyle(.plain)
      .accessibilityLabel("사진 저장")
    }
  }

  /// 지금 보고 있는 사진 한 장입니다.
  private var selectedPhotoNotes: [Note] {
    photos.filter { $0.id == selectedID }
  }

  @ViewBuilder private var shareButton: some View {
    if let image = selectedImage {
      ShareLink(item: Image(uiImage: image), preview: SharePreview("사진", image: Image(uiImage: image))) {
        PreviewActionIcon(.share)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("공유")
    } else {
      PreviewActionIcon(.share)
        .opacity(0.4)
    }
  }

  /// 사진들을 보낸 순서대로 사진 앱에 저장합니다. 한 장씩 저장해 실패한 장수를 알 수 있게 합니다.
  private func save(_ notes: [Note], scope: PhotoSaveScope) async {
    let images = notes.compactMap { $0.imageData.flatMap { UIImage(data: $0) } }
    // 메인 액터에서 확인과 표시를 한 번에 하므로, 버튼을 빠르게 두 번 눌러도 저장은 한 번만 시작된다.
    guard !images.isEmpty, !isSaving else {
      return
    }
    isSaving = true
    defer { isSaving = false }

    switch await PermissionChecker.requestPhotoSaveAccess() {
    case .granted:
      var savedCount = 0
      for image in images {
        do {
          try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
          }
          savedCount += 1
        } catch {
          continue
        }
      }
      // 사진 데이터를 읽지 못한 노트도 저장하지 못한 것으로 센다.
      let failedCount = notes.count - savedCount
      let feedback = PhotoSaveFeedback.result(scope: scope, savedCount: savedCount, failedCount: failedCount)
      toast = Toast(message: feedback.message, style: feedback.isSuccess ? .success : .failure)
    case .declinedInPrompt:
      break
    case .previouslyDenied:
      deniedPermission = .photoLibrary
    }
  }

  private func copyToPasteboard() {
    guard let image = selectedImage else {
      return
    }
    UIPasteboard.general.image = image
    toast = Toast(message: "사진이 복사되었습니다", style: .success)
  }

  private func requestDeleteConfirmation() {
    confirmationAlert = DestructiveConfirmationAlert(
      title: "이 사진을\n삭제하시겠습니까?",
      message: "삭제한 사진은 복구할 수 없어요",
      acknowledgementText: nil
    ) {
      deleteSelectedPhoto()
    }
  }

  private func deleteSelectedPhoto() {
    let currentPhotos = photos
    guard let index = currentPhotos.firstIndex(where: { $0.id == selectedID }) else {
      return
    }
    guard viewModel.deleteMessage(id: selectedID) else {
      toast = Toast(message: "사진 삭제 실패했습니다", style: .failure)
      return
    }

    // 남은 사진이 있으면 이웃 사진을 보여주고, 없으면 채팅으로 돌아간다.
    let remaining = photos
    if remaining.isEmpty {
      dismiss()
    } else {
      selectedID = remaining[min(index, remaining.count - 1)].id
    }
  }
}
