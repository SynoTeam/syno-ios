import PhotosUI
import SwiftUI
import UIKit

/// 앨범 선택, 카메라 촬영, 사진 확인 시트로 이어지는 사진 첨부 흐름을 화면에 붙이는 modifier입니다.
/// 앨범과 카메라를 띄울지는 바깥(입력 메뉴, 카메라 권한 확인)이 정하므로 `Binding`으로 받고,
/// 고른 사진을 불러와 줄이고 확인 시트로 넘기는 과정의 상태는 이 안에서만 관리합니다.
struct ChatPhotoAttachmentModifier: ViewModifier {
  @Binding var isShowingPhotosPicker: Bool
  @Binding var isShowingCamera: Bool
  /// 확인 시트에서 보내기를 누르면 줄여 둔 사진 데이터를 순서대로 전달합니다.
  let onSend: ([Data]) -> Void
  let onToast: (Toast) -> Void

  @State private var selectedPhotoItems: [PhotosPickerItem] = []
  @State private var pendingCameraImage: UIImage?
  @State private var pendingPhotoConfirmation: PhotoConfirmationRequest?

  /// 한 번에 고를 수 있는 앨범 사진 최대 개수입니다.
  private static let maxPhotoSelectionCount = 10

  func body(content: Content) -> some View {
    content
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
        // 여러 장이면 한 묶음으로 저장되어 채팅에서 하나의 콜라주 말풍선으로 보인다.
        ChatPhotoConfirmationView(photos: request.photos, onSend: onSend)
          .presentationDetents([.medium])
          .presentationDragIndicator(.visible)
      }
  }

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
      onToast(Toast(message: "사진을 불러오지 못했습니다.", style: .failure))
      return
    }

    if photos.count < items.count {
      onToast(Toast(message: "일부 사진을 불러오지 못했습니다.", style: .failure))
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
          onToast(Toast(message: "사진을 불러오지 못했습니다.", style: .failure))
        }
      }
    }
  }
}

extension View {
  /// 앨범 선택, 카메라 촬영, 사진 확인 시트를 붙입니다.
  func chatPhotoAttachment(
    isShowingPhotosPicker: Binding<Bool>,
    isShowingCamera: Binding<Bool>,
    onSend: @escaping ([Data]) -> Void,
    onToast: @escaping (Toast) -> Void
  ) -> some View {
    modifier(
      ChatPhotoAttachmentModifier(
        isShowingPhotosPicker: isShowingPhotosPicker,
        isShowingCamera: isShowingCamera,
        onSend: onSend,
        onToast: onToast
      )
    )
  }
}
