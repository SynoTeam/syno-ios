//
//  ChatMessageBubble.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import SwiftUI
import UIKit

/// 내가 남긴 기록을 오른쪽 말풍선으로 표시하는 채팅 메시지 컴포넌트입니다.
struct ChatMessageBubble: View {
  let note: Note
  var pendingStatus: ChatViewModel.PendingMessage.Status?
  var onRetry: (() -> Void)?
  var onDelete: (() -> Void)?
  var onShare: (() -> Void)?
  var onShowFullText: (() -> Void)?
  var linkPreview: NoteLinkPreviewResult?
  var highlightQuery: String?

  var body: some View {
    messageStack
    .frame(maxWidth: .infinity, alignment: .trailing)
    .contextMenu {
      Button {
        UIPasteboard.general.string = note.content
      } label: {
        Label("복사하기", systemImage: "doc.on.doc")
      }

      if let onShare {
        Button(action: onShare) {
          Label("공유하기", systemImage: "square.and.arrow.up")
        }
      }

      if let onDelete {
        Button(role: .destructive, action: onDelete) {
          Label("삭제하기", systemImage: "trash")
        }
      }
    }
  }

  private var messageStack: some View {
    VStack(alignment: .trailing, spacing: 4) {
      messageContent

      if let linkPreview {
        LinkPreviewCard(preview: linkPreview)
      }

      Text(note.clockTimeText)
        .typeStyle(.caption1)
        .foregroundStyle(.gray500)

      if let pendingStatus {
        pendingStatusView(pendingStatus)
      }
    }
    .frame(maxWidth: 280, alignment: .trailing)
    .contentShape(Rectangle())
  }

  @ViewBuilder
  private var messageContent: some View {
    if
      let imageData = note.imageData,
      let uiImage = UIImage(data: imageData)
    {
      Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 220, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    } else {
      VStack(alignment: .leading, spacing: 0) {
        contentText
          .typeStyle(.body)
          .foregroundStyle(.gray900)
          .multilineTextAlignment(.leading)
          .lineLimit(shouldShowFullTextLink ? 10 : nil)

        if shouldShowFullTextLink, let onShowFullText {
          Divider()
            .padding(.vertical, 10)

          Button(action: onShowFullText) {
            HStack {
              Text("전체보기")
                .typeStyle(.footnoteEmphasized)
                .foregroundStyle(.gray900)

              Spacer()

              Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
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

  private var shouldShowFullTextLink: Bool {
    note.content.count > 180
  }

  private var contentText: Text {
    guard
      let highlightQuery,
      !highlightQuery.isEmpty
    else {
      return Text(note.content)
    }

    var attributed = AttributedString(note.content)
    if let range = attributed.range(of: highlightQuery, options: .caseInsensitive) {
      attributed[range].backgroundColor = .violet200
    }
    return Text(attributed)
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

        if let onRetry {
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
