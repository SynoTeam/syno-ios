import SwiftUI

struct FileCard: View {
  let note: Note
  var downloadState: ChatViewModel.FileDownloadState?
  var onRetryDownload: (() -> Void)?
  var onOpen: (() -> Void)?

  var body: some View {
    Button(action: { onOpen?() }) {
      ZStack(alignment: .center) {
        Image(.messageFile)
          .resizable()
          .frame(width: 120, height: 100)

        VStack(alignment: .leading, spacing: 2) {
          Text(note.fileName ?? note.content)
            .typeStyle(.caption2Emphasized)
            .foregroundStyle(.bgBlack)
            .lineLimit(1)
          Text(ByteCountFormatter.string(fromByteCount: Int64(note.fileSize ?? 0), countStyle: .file))
            .typeStyle(.caption2)
            .foregroundStyle(.gray600)
        }
        .padding(.horizontal, 10)
        .frame(width: 120, alignment: .leading)
      }
      .frame(width: 120, height: 100)
      .overlay(alignment: .bottomTrailing) {
        downloadBadge
          .padding(.trailing, 6)
          .padding(.bottom, 6)
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder private var downloadBadge: some View {
    if note.fileData == nil {
      switch downloadState {
      case .checking:
        Circle()
          .fill(.gray50)
          .frame(width: 24, height: 24)
          .overlay { ProgressView().controlSize(.mini).tint(.gray500) }
      case .failed, nil:
        // 실패 표시(빨간 텍스트 + 재시도 버튼)는 카드 바깥, ChatMessageBubble에서 보여줘서
        // 여기 배지는 실패했든 아직 안 받았든 항상 같은 다운로드 아이콘으로 둡니다.
        Button(action: { onRetryDownload?() }) {
          Circle()
            .fill(.gray50)
            .frame(width: 24, height: 24)
            .overlay {
              Image(systemName: "arrow.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.gray500)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("파일 다운로드")
      }
    }
  }
}
