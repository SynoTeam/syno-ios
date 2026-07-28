//
//  AddContactPhotoPickerView.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import PhotosUI
import SwiftUI
import UIKit

/// 연락처 프로필 사진을 앨범 또는 카메라에서 선택하는 컴포넌트입니다.
struct AddContactPhotoPickerView: View {
  /// 부모 폼 상태와 연결된 선택 이미지 데이터입니다.
  @Binding var selectedImageData: Data?

  /// PhotosPicker에서 선택한 임시 이미지 아이템입니다.
  @State private var selectedPhotoItem: PhotosPickerItem?

  /// 앨범 선택 화면 표시 여부입니다.
  @State private var isShowingPhotoPicker = false

  /// 카메라 촬영 화면 표시 여부입니다.
  @State private var isShowingCamera = false

  /// 카메라 시트가 닫힌 뒤 크롭 화면으로 넘길 이미지입니다.
  @State private var pendingCameraImage: UIImage?

  /// 크롭 화면에 표시할 원본 이미지입니다.
  @State private var cropRequest: PhotoCropRequest?

  /// 이미지 로드 또는 렌더링 실패 알림입니다.
  @State private var toast: Toast?

  var body: some View {
    VStack(spacing: 20) {
      profileImage
      photoMenu
    }
    .frame(maxWidth: .infinity)
    .sheet(isPresented: $isShowingCamera, onDismiss: presentPendingCameraImage) {
      CameraPickerView { image in
        pendingCameraImage = image
      }
      .ignoresSafeArea()
    }
    .fullScreenCover(item: $cropRequest) { request in
      PhotoCropView(
        image: request.image,
        onComplete: { selectedImageData = $0 }
      )
    }
    .toast(item: $toast)
  }

  private var profileImage: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 25.6)
        .fill(.gray100)
        .frame(width: 96, height: 96)

      if
        let selectedImageData,
        let uiImage = UIImage(data: selectedImageData)
      {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 96, height: 96)
          .clipShape(RoundedRectangle(cornerRadius: 25.6))
      }
    }
  }

  private var photoMenu: some View {
    Menu {
      Button {
        openCamera()
      } label: {
        Label("사진 촬영하기", systemImage: "camera")
      }

      Button {
        isShowingPhotoPicker = true
      } label: {
        Label("앨범 선택하기", systemImage: "photo")
      }
    } label: {
      Text("사진 선택하기")
        .typeStyle(.subheadline)
        .foregroundStyle(.gray700)
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(.gray100)
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }
    .tint(.gray700)
    .photosPicker(
      isPresented: $isShowingPhotoPicker,
      selection: $selectedPhotoItem,
      matching: .images
    )
    .onChange(of: selectedPhotoItem) { _, selectedPhotoItem in
      Task {
        await loadImage(from: selectedPhotoItem)
      }
    }
  }

  private func loadImage(from item: PhotosPickerItem?) async {
    guard let item else {
      return
    }

    do {
      guard
        let data = try await item.loadTransferable(type: Data.self),
        let image = UIImage(data: data)
      else {
        showFailureToast("사진을 불러오지 못했습니다.")
        return
      }

      cropRequest = PhotoCropRequest(image: image)
    } catch {
      showFailureToast("사진을 불러오지 못했습니다.")
    }
  }

  private func openCamera() {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      showFailureToast("이 기기에서는 카메라를 사용할 수 없습니다.")
      return
    }

    isShowingCamera = true
  }

  private func presentPendingCameraImage() {
    guard let pendingCameraImage else {
      return
    }

    self.pendingCameraImage = nil
    cropRequest = PhotoCropRequest(image: pendingCameraImage)
  }

  private func showFailureToast(_ message: String) {
    toast = Toast(message: message, style: .failure)
  }
}

private struct PhotoCropRequest: Identifiable {
  let id = UUID()
  let image: UIImage
}
