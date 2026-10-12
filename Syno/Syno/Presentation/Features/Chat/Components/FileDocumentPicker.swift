import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// 앱 샌드박스에 복사한 파일 URL을 반환하는 문서 선택기입니다.
struct FileDocumentPicker: UIViewControllerRepresentable {
  /// 선택할 수 있는 파일 형식입니다. 기본값은 모든 파일입니다.
  var contentTypes: [UTType] = [.item]
  let onPick: (URL) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onPick: onPick)
  }

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: contentTypes,
      asCopy: true
    )
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

  final class Coordinator: NSObject, UIDocumentPickerDelegate {
    private let onPick: (URL) -> Void

    init(onPick: @escaping (URL) -> Void) {
      self.onPick = onPick
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      guard let url = urls.first else { return }
      onPick(url)
    }
  }
}
