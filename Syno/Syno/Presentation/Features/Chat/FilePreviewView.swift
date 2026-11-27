import QuickLook
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct FilePreviewView: View {
  @Environment(\.dismiss) private var dismiss
  let viewModel: ChatViewModel
  let noteID: Note.ID

  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var isQuickLookPresented = false

  private var note: Note? {
    viewModel.messages.first { $0.id == noteID }
  }

  private var downloadState: ChatViewModel.FileDownloadState? {
    viewModel.fileDownloadStates[noteID]
  }

  private var fileURL: URL? {
    viewModel.fileTransferURLs[noteID]
  }

  var body: some View {
    Group {
      if let note {
        content(for: note)
      } else {
        // 미리보기가 열려있는 동안 노트가 삭제된 경우입니다.
        Color.clear.onAppear { dismiss() }
      }
    }
    .background(Color.gray50)
    .navigationTitle("파일")
    .navigationBarTitleDisplayMode(.inline)
    .synoBackButton()
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .sheet(isPresented: $isQuickLookPresented) {
      if let fileURL {
        QuickLookPreview(url: fileURL)
          .ignoresSafeArea()
      }
    }
  }

  private func content(for note: Note) -> some View {
    VStack(spacing: 20) {
      Group {
        if let fileURL {
          QuickLookPreview(url: fileURL)
        } else {
          Image(.file)
            .resizable()
            .renderingMode(.template)
            .frame(width: 72, height: 72)
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

      actionRow(for: note)
    }
    .padding(16)
  }

  private func actionRow(for note: Note) -> some View {
    PreviewActionBar {
      Button(action: { viewModel.retryFileDownload(for: note) }) {
        PreviewActionIcon(.download)
      }
      .buttonStyle(.plain)
      .disabled(note.fileData != nil || downloadState == .checking)
      .opacity(note.fileData != nil || downloadState == .checking ? 0.4 : 1)
      .accessibilityLabel("다운로드")

      if let fileURL {
        ShareLink(item: fileURL, preview: SharePreview(note.fileName ?? "파일")) {
          PreviewActionIcon(.share)
        }
        .buttonStyle(.plain)
      } else {
        Button(action: {}) {
          PreviewActionIcon(.share)
        }
        .buttonStyle(.plain)
        .disabled(true)
        .opacity(0.4)
      }

      Button(action: { copyFileToPasteboard(note) }) {
        PreviewActionIcon(.copy)
      }
      .buttonStyle(.plain)
      .disabled(note.fileData == nil)
      .opacity(note.fileData == nil ? 0.4 : 1)
      .accessibilityLabel("복사하기")

      Button(action: { requestDeleteConfirmation(note) }) {
        PreviewActionIcon(.trash)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("삭제")
    }
  }

  private func copyFileToPasteboard(_ note: Note) {
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
      Label("iCloud에서 파일을 확인하는 중", icon: .refresh)
        .typeStyle(.footnote).foregroundStyle(.gray500)
    case .failed:
      Label("파일을 가져오지 못했습니다. 다시 시도해주세요.", systemImage: "exclamationmark.triangle")
        .typeStyle(.footnote).foregroundStyle(.errorRed)
    case nil:
      Label("파일 다운로드가 필요합니다.", systemImage: "arrow.down.circle")
        .typeStyle(.footnote).foregroundStyle(.gray500)
    }
  }

  private func requestDeleteConfirmation(_ note: Note) {
    confirmationAlert = DestructiveConfirmationAlert(
      title: "이 파일을\n삭제하겠습니까?",
      message: "삭제한 항목은 복구할 수 없습니다.",
      acknowledgementText: nil
    ) {
      if viewModel.deleteMessage(id: note.id) { dismiss() }
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
  /// note.fileData를 임시 파일로 씁니다. 디스크 I/O이므로 백그라운드에서 실행되어 메인 스레드(뷰 렌더링)를
  /// 막지 않습니다. 같은 노트에 대해 이미 같은 크기의 파일이 디스크에 있으면 다시 쓰지 않습니다.
  static func prepare(for note: Note) async -> URL? {
    guard let data = note.fileData else { return nil }
    return await prepare(data: data, name: note.fileName ?? "file", noteID: note.id)
  }

  /// 파일 대신 다른 데이터(음성 메모 등)를 같은 방식으로 임시 파일로 씁니다 (#144).
  /// 노트마다 폴더를 따로 두어 파일 이름은 `name` 그대로 보입니다(공유·파일 앱 저장에서 사용자에게 보이는 이름).
  /// 제목이 바뀌어 다른 이름으로 준비하면 그 노트의 예전 이름 파일은 지웁니다.
  /// `overwrite`가 true면 같은 이름·크기의 파일이 있어도 다시 씁니다(복사용 폴더처럼 내용이 바뀌는 경우).
  static func prepare(data: Data, name: String, noteID: Note.ID, overwrite: Bool = false) async -> URL? {
    let folder = folderURL(forNoteID: noteID)
    return await Task.detached(priority: .utility) {
      let fileManager = FileManager.default
      let url = folder.appendingPathComponent(name)
      if !overwrite,
         let existingSize = try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int,
         existingSize == data.count {
        return url
      }
      do {
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let oldFiles = (try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        for oldFile in oldFiles where oldFile.lastPathComponent != name {
          try? fileManager.removeItem(at: oldFile)
        }
        try data.write(to: url, options: .atomic)
        return url
      } catch {
        return nil
      }
    }.value
  }

  /// 노트가 삭제될 때 그 노트를 위해 만들어둔 임시 파일도 같이 정리합니다.
  static func removeTemporaryFile(for noteID: Note.ID) {
    let folder = folderURL(forNoteID: noteID)
    let root = directory
    Task.detached(priority: .utility) {
      removeFiles(folder: folder, root: root, noteID: noteID)
    }
  }

  /// 바로 지웁니다. 테스트에서 씁니다.
  static func removeTemporaryFileNow(for noteID: Note.ID) {
    removeFiles(folder: folderURL(forNoteID: noteID), root: directory, noteID: noteID)
  }

  private nonisolated static func removeFiles(folder: URL, root: URL, noteID: Note.ID) {
    let fileManager = FileManager.default
    try? fileManager.removeItem(at: folder)
    // 예전 방식("노트ID-이름")으로 만든 파일도 정리합니다.
    let prefix = "\(noteID.uuidString)-"
    let files = (try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
    for file in files where file.lastPathComponent.hasPrefix(prefix) {
      try? fileManager.removeItem(at: file)
    }
  }

  /// 복사(붙여넣기)용 파일을 두는 폴더입니다. 노트 폴더와 따로 두어 한 번에 한 파일만 남깁니다 (#144).
  static let clipboardFolderID = UUID(uuidString: "00000000-0000-0000-0000-00000000C11B")!

  private static var directory: URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("SynoFiles", isDirectory: true)
  }

  private static func folderURL(forNoteID noteID: Note.ID) -> URL {
    directory.appendingPathComponent(noteID.uuidString, isDirectory: true)
  }
}
