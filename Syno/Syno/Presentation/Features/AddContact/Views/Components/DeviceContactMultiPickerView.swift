//
//  DeviceContactMultiPickerView.swift
//  Syno
//

import Contacts
import ContactsUI
import SwiftUI

/// 휴대폰 연락처 여러 개를 한 번에 선택할 수 있게 감싸는 래퍼입니다.
struct DeviceContactMultiPickerView: UIViewControllerRepresentable {
  /// 사용자가 선택한 연락처 목록을 부모 뷰로 전달하는 콜백입니다.
  let onSelect: ([CNContact]) -> Void

  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> CNContactPickerViewController {
    let picker = CNContactPickerViewController()
    picker.delegate = context.coordinator
    // 이 predicate를 false로 두면 단일 선택 즉시 종료 대신 체크박스 다중 선택 모드로 동작합니다.
    picker.predicateForSelectionOfContact = NSPredicate(value: false)
    return picker
  }

  func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(onSelect: onSelect, dismiss: dismiss)
  }
}

extension DeviceContactMultiPickerView {
  final class Coordinator: NSObject, CNContactPickerDelegate {
    private let onSelect: ([CNContact]) -> Void
    private let dismiss: DismissAction

    init(
      onSelect: @escaping ([CNContact]) -> Void,
      dismiss: DismissAction
    ) {
      self.onSelect = onSelect
      self.dismiss = dismiss
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
      onSelect(contacts)
      dismiss()
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
      dismiss()
    }
  }
}
