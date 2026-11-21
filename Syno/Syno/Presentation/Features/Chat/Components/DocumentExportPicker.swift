import SwiftUI
import UIKit

/// 파일 앱의 "저장 위치 선택" 화면을 띄워 파일을 복사해 저장합니다 (#144).
/// 화면 표시와 사용자 선택만 하는 UI 어댑터입니다.
struct DocumentExportPicker: UIViewControllerRepresentable {
  let urls: [URL]
  /// 저장하면 true, 취소하면 false입니다.
  let onCompletion: (Bool) -> Void

  func makeCoordinator() -> Coordinator { Coordinator(onCompletion: onCompletion) }

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let picker = UIDocumentPickerViewController(forExporting: urls, asCopy: true)
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

  final class Coordinator: NSObject, UIDocumentPickerDelegate {
    let onCompletion: (Bool) -> Void
    init(onCompletion: @escaping (Bool) -> Void) { self.onCompletion = onCompletion }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      onCompletion(true)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
      onCompletion(false)
    }
  }
}
