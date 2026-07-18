//
//  CameraPickerView.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI
import UIKit

/// SwiftUI에서 UIKit 카메라 촬영 화면을 사용할 수 있게 감싸는 래퍼입니다.
struct CameraPickerView: UIViewControllerRepresentable {
  /// 촬영 또는 편집이 완료된 이미지를 부모 뷰로 전달하는 콜백입니다.
  let onImagePicked: (UIImage) -> Void

  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.allowsEditing = true
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(
      onImagePicked: onImagePicked,
      dismiss: dismiss
    )
  }
}

extension CameraPickerView {
  /// `UIImagePickerController`의 선택 및 취소 이벤트를 SwiftUI 콜백으로 연결하는 객체입니다.
  final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    private let onImagePicked: (UIImage) -> Void
    private let dismiss: DismissAction

    init(
      onImagePicked: @escaping (UIImage) -> Void,
      dismiss: DismissAction
    ) {
      self.onImagePicked = onImagePicked
      self.dismiss = dismiss
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage

      if let image {
        onImagePicked(image)
      }

      dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      dismiss()
    }
  }
}
