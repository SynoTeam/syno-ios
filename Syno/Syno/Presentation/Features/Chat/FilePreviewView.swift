import QuickLook
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct FilePreviewView: View {
  @Environment(\.dismiss) private var dismiss
  let note: Note
  var downloadState: ChatViewModel.FileDownloadState?
  var onRetryDownload: (() -> Void)?
  var onDelete: ((Note) -> Bool)?

  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var isQuickLookPresented = false

  var body: some View {
    VStack(spacing: 20) {
      Group {
        if let fileURL {
          QuickLookPreview(url: fileURL)
        } else {
          Image(systemName: "doc.fill")
            .font(.system(size: 72))
            .foregroundStyle(.violet500)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: 480)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 20))

      VStack(alignment: .center, spacing: 6) {
        Text(note.fileName ?? note.content)
          .typeStyle(.bodyEmphasized)
          .foregroundStyle(.bgBlack)
          .lineLimit(1)
          .truncationMode(.middle)
        Text(ByteCountFormatter.string(fromByteCount: Int64(note.fileSize ?? 0), countStyle: .file))
          .typeStyle(.caption1)
          .foregroundStyle(.gray600)
      }
      .frame(maxWidth: .infinity, alignment: .center)

      if fileURL != nil {
        Button("파일 열기") { isQuickLookPresented = true }
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.gray700)
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
          .background(.gray100)
          .clipShape(Capsule())
      }

      if note.fileData == nil {
        downloadStatus
      }

      actionRow
    }
    .padding(16)
    .background(Color.gray50)
    .navigationTitle("파일")
    .navigationBarTitleDisplayMode(.inline)
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .sheet(isPresented: $isQuickLookPresented) {
      if let fileURL {
        QuickLookPreview(url: fileURL)
          .ignoresSafeArea()
      }
    }
  }

  private var actionRow: some View {
    HStack {
      Button(action: { onRetryDownload?() }) {
        iconCircle(systemName: "arrow.down")
      }
      .buttonStyle(.plain)
      .disabled(note.fileData != nil || downloadState == .checking)
      .opacity(note.fileData == nil ? 1 : 0.35)
      .accessibilityLabel("다운로드")

      if let fileURL {
        ShareLink(item: fileURL, preview: SharePreview(note.fileName ?? "파일")) {
          iconCircle(systemName: "square.and.arrow.up")
        }
      } else {
        iconCircle(systemName: "square.and.arrow.up").opacity(0.35)
      }
      
      Spacer()

      Button(action: copyFileToPasteboard) {
        iconCircle(systemName: "doc.on.doc")
      }
      .buttonStyle(.plain)
      .disabled(note.fileData == nil)
      .opacity(note.fileData == nil ? 0.35 : 1)
      .accessibilityLabel("복사하기")
      
      Spacer()

      Button(action: requestDeleteConfirmation) {
        iconCircle(systemName: "trash")
      }
      .buttonStyle(.plain)
      .accessibilityLabel("삭제")
    }
    .padding(8)
    .frame(maxWidth: .infinity)
    .background {
      RoundedRectangle(cornerRadius: 999)
        .fill(.gray100)
    }
    .padding(.horizontal, 60)
  }

  private func iconCircle(systemName: String) -> some View {
    Circle()
      .fill(.bgWhite)
      .frame(width: 44, height: 44)
      .overlay {
        Image(systemName: systemName)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(.gray600)
      }
  }

  private func copyFileToPasteboard() {
    guard let data = note.fileData else { return }
    let type = note.fileName
      .flatMap { ($0 as NSString).pathExtension.isEmpty ? nil : ($0 as NSString).pathExtension }
      .flatMap { UTType(filenameExtension: $0) }
      ?? .data
    UIPasteboard.general.setData(data, forPasteboardType: type.identifier)
  }

  @ViewBuilder private var downloadStatus: some View {
    switch downloadState {
    case .checking:
      Label("iCloud에서 파일을 확인하는 중", systemImage: "arrow.triangle.2.circlepath")
        .typeStyle(.footnote).foregroundStyle(.gray500)
    case .failed:
      Label("파일을 가져오지 못했습니다. 다시 시도해주세요.", systemImage: "exclamationmark.triangle")
        .typeStyle(.footnote).foregroundStyle(.errorRed)
    case nil:
      Label("파일 다운로드가 필요합니다.", systemImage: "arrow.down.circle")
        .typeStyle(.footnote).foregroundStyle(.gray500)
    }
  }

  private var fileURL: URL? {
    FileTransferURL.temporaryURL(for: note)
  }

  private func requestDeleteConfirmation() {
    confirmationAlert = DestructiveConfirmationAlert(
      title: "이 파일을\n삭제하겠습니까?",
      message: "삭제한 항목은 복구할 수 없습니다.",
      acknowledgementText: nil
    ) {
      if onDelete?(note) == true { dismiss() }
    }
  }
}

private struct QuickLookPreview: UIViewControllerRepresentable {
  let url: URL

  func makeCoordinator() -> Coordinator { Coordinator(url: url) }

  func makeUIViewController(context: Context) -> QLPreviewController {
    let controller = QLPreviewController()
    controller.dataSource = context.coordinator
    return controller
  }

  func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

  final class Coordinator: NSObject, QLPreviewControllerDataSource {
    let url: URL
    init(url: URL) { self.url = url }
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { url as NSURL }
  }
}

enum FileTransferURL {
  /// note.fileData를 임시 파일로 써서 URL을 돌려줍니다. 같은 노트에 대해 이미 같은 크기의
  /// 파일이 디스크에 있으면 다시 쓰지 않습니다 — 이 함수가 SwiftUI body 재평가마다
  /// (다운로드 폴링 중이면 3초마다) 여러 번 호출될 수 있어서, 매번 큰 파일을 다시 쓰면
  /// 눈에 띄는 랙이 생깁니다.
  static func temporaryURL(for note: Note) -> URL? {
    guard let data = note.fileData else { return nil }
    let name = note.fileName ?? "file"
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("SynoFiles", isDirectory: true)
    let url = directory.appendingPathComponent("\(note.id.uuidString)-\(name)")

    if let existingSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int,
       existingSize == data.count {
      return url
    }

    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try data.write(to: url, options: .atomic)
      return url
    } catch {
      return nil
    }
  }
}
