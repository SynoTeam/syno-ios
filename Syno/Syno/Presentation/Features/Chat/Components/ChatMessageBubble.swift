//
//  ChatMessageBubble.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import SwiftUI
import UIKit

/// 말풍선에서 사용자가 할 수 있는 동작입니다. 값이 nil이면 그 동작을 제공하지 않습니다.
/// 예를 들어 `onDelete`가 없으면 길게 눌렀을 때 삭제 메뉴가 나타나지 않습니다.
struct ChatMessageActions {
  var onDelete: (() -> Void)?
  var onShowFullText: (() -> Void)?
  var onShowFile: (() -> Void)?
  var onShowPhoto: (() -> Void)?
  /// 저장하지 못해 대기 중인 메시지를 다시 저장합니다.
  var onRetryPendingSend: (() -> Void)?
  var onRetryTranscription: (() -> Void)?
  /// 전송에 실패한 음성 메모를 다시 보냅니다.
  var onRetryVoiceSend: (() -> Void)?
  var onRetryFileDownload: (() -> Void)?
  var onRetryFileSend: (() -> Void)?
}

/// 말풍선을 그릴 때 쓰는 서로 독립적인 표시 값입니다.
struct ChatMessageDisplayState {
  var pendingStatus: ChatViewModel.PendingMessage.Status?
  var linkPreview: NoteLinkPreviewResult?
  var voiceMemoState: ChatViewModel.VoiceMemoState?
  var fileDownloadState: ChatViewModel.FileDownloadState?
  var fileTransferURL: URL?
  var fileSendFailed: Bool = false
  var highlightQuery: String?
  /// 검색 결과로 이동해 온 메시지를 튀게 만들 때 true입니다.
  var isHighlighted: Bool = false
  /// 목록을 옆으로 밀었을 때 말풍선 오른쪽에 보여줄 시간입니다. 없으면 표시하지 않습니다.
  var revealedTimeText: String?
  /// 목록을 왼쪽으로 민 거리입니다. 0이면 시간이 숨겨져 있습니다.
  var timeRevealOffset: CGFloat = 0
}

/// 내가 남긴 기록을 오른쪽 말풍선으로 표시하는 채팅 메시지 컴포넌트입니다.
struct ChatMessageBubble: View {
  let note: Note
  var state = ChatMessageDisplayState()
  var actions = ChatMessageActions()

  var body: some View {
    ZStack(alignment: .trailing) {
      // 시간은 화면 오른쪽 끝에 고정하고, 말풍선만 왼쪽으로 밀려나 그 자리를 비운다.
      if let revealedTimeText = state.revealedTimeText {
        Text(revealedTimeText)
          .typeStyle(.caption1)
          .foregroundStyle(.gray400)
          .fixedSize()
          .offset(x: 8)
          .opacity(min(1, state.timeRevealOffset / 40))
      }

      bubbleWithMenu
        .frame(maxWidth: .infinity, alignment: .trailing)
        .offset(x: -state.timeRevealOffset)
    }
  }

  private var bubbleWithMenu: some View {
    messageStack
    .contextMenu {
      if note.fileName == nil {
        Button {
          UIPasteboard.general.string = note.content
        } label: {
          Label("복사하기", icon: .copy)
        }
      }

      shareLink

      if let onDelete = actions.onDelete {
        Button(role: .destructive, action: onDelete) {
          Label("삭제하기", icon: .trash)
        }
      }
    }
  }

  private var messageStack: some View {
    VStack(alignment: .trailing, spacing: 4) {
      messageContent

      if let linkPreview = state.linkPreview {
        LinkPreviewCard(preview: linkPreview)
      }
      if let voiceMemoState = state.voiceMemoState { voiceTranscriptView(voiceMemoState) }
      if state.fileSendFailed { transferFailedView(title: "전송 실패", onRetry: actions.onRetryFileSend) }

      if let pendingStatus = state.pendingStatus {
        pendingStatusView(pendingStatus)
      }
    }
    .frame(maxWidth: 298, alignment: .trailing)
    .contentShape(Rectangle())
    // 검색 결과로 이동해 온 메시지가 통통 튀어 위치를 알려준다.
    .scaleEffect(state.isHighlighted ? 1.08 : 1, anchor: .trailing)
    .animation(.spring(duration: 0.45, bounce: 0.6), value: state.isHighlighted)
  }

  @ViewBuilder
  private var messageContent: some View {
    if note.voiceMemoData != nil {
      VoiceMemoCard(note: note)
    } else if note.fileName != nil {
      FileCard(
        note: note,
        downloadState: state.fileDownloadState,
        onRetryDownload: actions.onRetryFileDownload,
        onOpen: actions.onShowFile
      )
    } else if
      let imageData = note.imageData,
      let uiImage = UIImage(data: imageData)
    {
      Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 220, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .onTapGesture {
          actions.onShowPhoto?()
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("사진 크게 보기")
    } else {
      VStack(alignment: .leading, spacing: 0) {
        contentText
          .typeStyle(.body)
          .foregroundStyle(.gray900)
          .multilineTextAlignment(.leading)
          .lineLimit(shouldShowFullTextLink ? 10 : nil)

        if shouldShowFullTextLink, let onShowFullText = actions.onShowFullText {
          Divider()
            .padding(.vertical, 10)

          Button(action: onShowFullText) {
            HStack {
              Text("전체보기")
                .typeStyle(.footnoteEmphasized)
                .foregroundStyle(.gray900)

              Spacer()

              Image(.chevronRight)
                .resizable()
                .renderingMode(.template)
                .frame(width: 16, height: 16)
                .foregroundStyle(.gray400)
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(.gray5)
      .clipShape(RoundedRectangle(cornerRadius: 24))
    }
  }

  @ViewBuilder private func voiceTranscriptView(_ state: ChatViewModel.VoiceMemoState) -> some View {
    switch state {
    case .transcribing:
      transcriptBox {
        HStack(spacing: 6) {
          ProgressView().controlSize(.small)
          Text("STT 변환 중")
            .typeStyle(.body)
            .foregroundStyle(.gray500)
        }
      }
    case let .transcribed(result):
      transcriptBox {
        Text(result.text)
          .typeStyle(.body)
          .foregroundStyle(.gray900)
          .multilineTextAlignment(.leading)
      }
    case .transcriptFailed:
      HStack {
        Text("STT 변환 실패")
          .foregroundStyle(.errorRed)
        if let onRetryTranscription = actions.onRetryTranscription {
          Button("다시 시도", action: onRetryTranscription)
            .foregroundStyle(.violet500)
        }
      }
      .typeStyle(.caption1)
    case .sendFailed:
      HStack {
        Text("전송에 실패했습니다")
        if let onRetryVoiceSend = actions.onRetryVoiceSend {
          Button("다시 시도", action: onRetryVoiceSend)
            .foregroundStyle(.violet500)
        }
      }
      .typeStyle(.caption1)
      .foregroundStyle(.errorRed)
    }
  }

  /// 음성 메모 아래에 붙는 STT 결과 말풍선입니다. 텍스트 말풍선과 같은 배경과 모서리를 쓰고 위쪽에 작은 라벨을 둡니다. 글이 짧으면 내용 길이에 맞춰지고 최대 폭은 말풍선 폭(298)입니다.
  private func transcriptBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("STT")
        .typeStyle(.footnoteEmphasized)
        .foregroundStyle(.gray400)

      content()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 16)
    .background(.gray5)
    .clipShape(RoundedRectangle(cornerRadius: 24))
  }

  private func transferFailedView(title: String, onRetry: (() -> Void)?) -> some View {
    HStack(spacing: 8) {
      Text(title)
        .typeStyle(.caption1Emphasized)
        .foregroundStyle(.errorRed)

      if let onRetry {
        Button(action: onRetry) {
          Circle()
            .fill(.bgError01)
            .frame(width: 24, height: 24)
            .overlay {
              Image(.refresh)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.errorRed)
                .frame(width: 14, height: 14)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("다시 시도")
      }
    }
  }

  private var shouldShowFullTextLink: Bool {
    note.content.count > 180
  }

  @ViewBuilder
  private var shareLink: some View {
    if let fileTransferURL = state.fileTransferURL {
      ShareLink(item: fileTransferURL, preview: SharePreview(note.fileName ?? "파일")) {
        Label("공유하기", icon: .share)
      }
    } else if let imageData = note.imageData, let uiImage = UIImage(data: imageData) {
      ShareLink(item: Image(uiImage: uiImage), preview: SharePreview("사진", image: Image(uiImage: uiImage))) {
        Label("공유하기", icon: .share)
      }
    } else if let linkPreview = state.linkPreview {
      ShareLink(item: linkPreview.siteURL) {
        Label("공유하기", icon: .share)
      }
    } else {
      ShareLink(item: note.content) {
        Label("공유하기", icon: .share)
      }
    }
  }

  /// 검색어와 일치하는 모든 부분을 하이라이트한 본문입니다. 검색 중이 아니면 일반 텍스트입니다.
  private var contentText: Text {
    Text(highlighting: note.content, query: state.highlightQuery)
  }

  @ViewBuilder
  private func pendingStatusView(_ status: ChatViewModel.PendingMessage.Status) -> some View {
    switch status {
    case .sending:
      HStack(spacing: 6) {
        ProgressView()
          .controlSize(.small)
        Text("전송 중")
      }
      .typeStyle(.caption1)
      .foregroundStyle(.gray500)
    case .failed:
      HStack(spacing: 8) {
        Text("전송에 실패했습니다")
          .typeStyle(.caption1)
          .foregroundStyle(.errorRed)

        if let onRetry = actions.onRetryPendingSend {
          Button("다시 시도", action: onRetry)
            .typeStyle(.caption1)
            .foregroundStyle(.violet500)
        }
      }
    }
  }
}

struct LinkPreviewCard: View {
  let preview: NoteLinkPreviewResult

  var body: some View {
    Link(destination: preview.siteURL) {
      VStack(alignment: .leading, spacing: 0) {
        if let imageURL = preview.imageURL {
          AsyncImage(url: imageURL) { image in
            image.resizable().aspectRatio(contentMode: .fill)
          } placeholder: {
            Color.gray100
          }
          .frame(maxWidth: .infinity)
          .frame(height: 120)
          .clipped()
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(preview.title)
            .typeStyle(.footnoteEmphasized)
            .foregroundStyle(.gray900)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
          Text(preview.siteURL.host ?? preview.siteURL.absoluteString)
            .typeStyle(.caption1)
            .foregroundStyle(.violet500)
            .underline()
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
      }
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .buttonStyle(.plain)
  }
}

#Preview("전송 실패 재시도") {
  ChatMessageBubble(
    note: Note(contactName: "테스트", content: "파일.zip", fileName: "파일.zip", fileSize: 27_000_000),
    state: ChatMessageDisplayState(fileSendFailed: true),
    actions: ChatMessageActions(onRetryFileSend: {})
  )
  .padding()
  .background(Color.gray50)
}
