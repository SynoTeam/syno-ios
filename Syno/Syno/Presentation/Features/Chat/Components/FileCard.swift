import SwiftUI

struct FileCard: View {
  let note: Note
  var downloadState: ChatViewModel.FileDownloadState?
  var onRetryDownload: (() -> Void)?
  var onOpen: (() -> Void)?

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      cardFace

      if note.fileData == nil {
        downloadBadge
          .padding(.trailing, 6)
          .padding(.bottom, 6)
      }
    }
    .frame(width: 120, height: 100)
  }

  /// onOpen이 있을 때만(=이 카드가 NavigationLink 같은 다른 인터랙티브 컨트롤의 label로 안 쓰일 때만)
  /// 탭 제스처를 붙입니다. ArchiveView처럼 NavigationLink의 label로 쓰일 땐 onOpen을 안 넘겨서,
  /// 이 카드 자체는 아무 컨트롤도 없는 순수 표시용 뷰가 되고 NavigationLink가 탭을 전담합니다.
  @ViewBuilder private var cardFace: some View {
    let face = ZStack(alignment: .center) {
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

    if let onOpen {
      face
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    } else {
      face
    }
  }

  /// onRetryDownload가 없으면(=ArchiveView처럼 이 카드가 NavigationLink 안에 놓일 때) 배지를 순수
  /// 표시용으로만 그립니다. 그 경우 실제 재시도 버튼은 호출자가 NavigationLink와 형제 컨트롤로
  /// 따로 둡니다 — NavigationLink의 label 안에 또 다른 Button을 넣으면 탭 히트테스트가 꼬입니다.
  @ViewBuilder private var downloadBadge: some View {
    switch downloadState {
    case .checking:
      FileDownloadBadgeIcon { ProgressView().controlSize(.mini).tint(.gray500) }
    case .failed, nil:
      if let onRetryDownload {
        Button(action: onRetryDownload) {
          FileDownloadBadgeIcon { downloadArrow }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("파일 다운로드")
      } else {
        FileDownloadBadgeIcon { downloadArrow }
      }
    }
  }

  private var downloadArrow: some View {
    Image(systemName: "arrow.down")
      .font(.system(size: 14, weight: .bold))
      .foregroundStyle(.gray500)
  }
}

/// FileCard와 ArchiveView가 똑같은 모양의 다운로드 배지를 그릴 때 공유하는 작은 원형 컨테이너입니다.
struct FileDownloadBadgeIcon<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    Circle()
      .fill(.gray50)
      .frame(width: 24, height: 24)
      .overlay { content }
  }
}
