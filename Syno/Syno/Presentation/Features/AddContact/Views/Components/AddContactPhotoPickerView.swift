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

  /// 프로필 사진 선택지를 보여주는 알럿입니다.
  @State private var photoAlert: ActionChoiceAlert?

  /// 카메라 권한이 거부되었을 때 설정 이동을 안내하는 알럿입니다.
  @State private var deniedPermission: PermissionKind?

  var body: some View {
    photoMenu
      .actionChoiceAlert(item: $photoAlert)
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
    .permissionDeniedAlert($deniedPermission)
  }

  /// 사진이 없으면 + 아이콘을, 있으면 사진과 오른쪽 아래 카메라 버튼을 보여줍니다.
  private var profileImage: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 25.6, style: .continuous)
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
          .clipShape(RoundedRectangle(cornerRadius: 25.6, style: .continuous))
      } else {
        Image(.plus)
          .resizable()
          .renderingMode(.template)
          .frame(width: 32, height: 32)
          .foregroundStyle(.gray400)
      }
    }
    .overlay(alignment: .bottomTrailing) {
      if selectedImageData != nil {
        Image(.camera)
          .resizable()
          .renderingMode(.template)
          .frame(width: 20, height: 20)
          .foregroundStyle(.gray400)
          .frame(width: 28, height: 28)
          .background(.gray100)
          .clipShape(Circle())
          // 바깥에 흰 테두리를 둘러 사진과 구분한다. 지름은 테두리 포함 32pt.
          .padding(2)
          .background(.white)
          .clipShape(Circle())
          .offset(x: 8, y: 8)
      }
    }
    .accessibilityLabel("프로필 사진 선택")
  }

  private var photoMenu: some View {
    Button {
      photoAlert = ActionChoiceAlert(
        title: "프로필 사진",
        actions: photoAlertActions
      )
    } label: {
      profileImage
    }
    .buttonStyle(.plain)
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

  private var photoAlertActions: [ActionChoiceAlert.Action] {
    var actions = [
      ActionChoiceAlert.Action(title: "사진 촬영하기") {
        Task { await openCamera() }
      },
      ActionChoiceAlert.Action(title: "앨범 선택하기") {
        isShowingPhotoPicker = true
      }
    ]

    if selectedImageData != nil {
      actions.append(
        ActionChoiceAlert.Action(title: "기본 이미지로 설정하기") {
          selectedImageData = nil
        }
      )
    }
    return actions
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

  private func openCamera() async {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      showFailureToast("이 기기에서는 카메라를 사용할 수 없습니다.")
      return
    }

    switch await PermissionChecker.requestCameraAccess() {
    case .granted:
      isShowingCamera = true
    case .declinedInPrompt:
      break
    case .previouslyDenied:
      deniedPermission = .camera
    }
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
