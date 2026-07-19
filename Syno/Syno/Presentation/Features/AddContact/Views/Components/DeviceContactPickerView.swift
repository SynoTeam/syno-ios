//
//  DeviceContactPickerView.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import Contacts
import ContactsUI
import SwiftUI

/// iOS 기본 연락처 선택 화면을 SwiftUI에서 사용할 수 있게 감싸는 래퍼입니다.
struct DeviceContactPickerView: UIViewControllerRepresentable {
  /// 사용자가 선택한 휴대폰 연락처를 부모 뷰로 전달하는 콜백입니다.
  let onSelect: (CNContact) -> Void

  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> CNContactPickerViewController {
    let picker = CNContactPickerViewController()
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(
      onSelect: onSelect,
      dismiss: dismiss
    )
  }
}

extension DeviceContactPickerView {
  /// 연락처 선택 및 취소 이벤트를 SwiftUI 콜백으로 연결하는 객체입니다.
  final class Coordinator: NSObject, CNContactPickerDelegate {
    private let onSelect: (CNContact) -> Void
    private let dismiss: DismissAction

    init(
      onSelect: @escaping (CNContact) -> Void,
      dismiss: DismissAction
    ) {
      self.onSelect = onSelect
      self.dismiss = dismiss
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
      onSelect(contact)
      dismiss()
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
      dismiss()
    }
  }
}
