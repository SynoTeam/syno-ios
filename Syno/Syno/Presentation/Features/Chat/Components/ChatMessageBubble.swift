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

  var body: some View {
    VStack(alignment: .trailing, spacing: 4) {
      messageContent

      Text(note.clockTimeText)
        .typeStyle(.caption1)
        .foregroundStyle(.gray500)

      if let pendingStatus {
        pendingStatusView(pendingStatus)
      }
    }
    .frame(maxWidth: 280, alignment: .trailing)
    .contextMenu {
      Button {
        UIPasteboard.general.string = note.content
      } label: {
        Label("복사하기", systemImage: "doc.on.doc")
      }

      if let onDelete {
        Button(role: .destructive, action: onDelete) {
          Label("삭제하기", systemImage: "trash")
        }
      }
    }
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
      Text(note.content)
        .typeStyle(.body)
        .foregroundStyle(.gray900)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.gray5)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
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
