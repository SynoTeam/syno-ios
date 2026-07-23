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

  var body: some View {
    VStack(alignment: .trailing, spacing: 4) {
      messageContent

      Text(note.timeText)
        .typeStyle(.caption1)
        .foregroundStyle(.gray500)
    }
    .frame(maxWidth: 280, alignment: .trailing)
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
}
