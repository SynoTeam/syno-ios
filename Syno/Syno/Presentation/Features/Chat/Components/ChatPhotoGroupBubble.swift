import SwiftUI
import UIKit

/// 앨범에서 한 번에 보낸 여러 장의 사진을 카카오톡처럼 하나의 콜라주 말풍선으로 보여줍니다.
/// 2장은 좌우로, 3장은 왼쪽 큰 사진과 오른쪽 두 장으로, 4장 이상은 2x2로 나누고 남는 장수는 마지막 칸에 "+N"으로 표시합니다.
struct ChatPhotoGroupBubble: View {
  let notes: [Note]
  var onDelete: (() -> Void)?
  var onShowPhoto: ((Note) -> Void)?
  var isHighlighted: Bool = false
  var revealedTimeText: String?
  var timeRevealOffset: CGFloat = 0

  private static let side: CGFloat = 220
  private static let gap: CGFloat = 2
  private static let half: CGFloat = (side - gap) / 2

  var body: some View {
    ZStack(alignment: .trailing) {
      if let revealedTimeText {
        Text(revealedTimeText)
          .typeStyle(.caption1)
          .foregroundStyle(.gray400)
          .fixedSize()
          .offset(x: 8)
          .opacity(min(1, timeRevealOffset / 40))
      }

      collage
        .frame(width: Self.side, height: Self.side)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .contextMenu {
          ShareLink(items: images) { image in
            SharePreview("사진", image: image)
          } label: {
            Label("공유하기", icon: .share)
          }

          if let onDelete {
            Button(role: .destructive, action: onDelete) {
              Label("삭제하기", icon: .trash)
            }
          }
        }
        .scaleEffect(isHighlighted ? 1.08 : 1, anchor: .trailing)
        .animation(.spring(duration: 0.45, bounce: 0.6), value: isHighlighted)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .offset(x: -timeRevealOffset)
    }
  }

  private var images: [Image] {
    notes.compactMap { note in
      note.imageData.flatMap { UIImage(data: $0) }.map { Image(uiImage: $0) }
    }
  }

  @ViewBuilder
  private var collage: some View {
    switch notes.count {
    case 0, 1:
      EmptyView()
    case 2:
      HStack(spacing: Self.gap) {
        cell(notes[0], width: Self.half, height: Self.side)
        cell(notes[1], width: Self.half, height: Self.side)
      }
    case 3:
      HStack(spacing: Self.gap) {
        cell(notes[0], width: Self.half, height: Self.side)
        VStack(spacing: Self.gap) {
          cell(notes[1], width: Self.half, height: Self.half)
          cell(notes[2], width: Self.half, height: Self.half)
        }
      }
    default:
      let extra = notes.count - 4
      VStack(spacing: Self.gap) {
        HStack(spacing: Self.gap) {
          cell(notes[0], width: Self.half, height: Self.half)
          cell(notes[1], width: Self.half, height: Self.half)
        }
        HStack(spacing: Self.gap) {
          cell(notes[2], width: Self.half, height: Self.half)
          cell(notes[3], width: Self.half, height: Self.half, extraCount: extra)
        }
      }
    }
  }

  private func cell(_ note: Note, width: CGFloat, height: CGFloat, extraCount: Int = 0) -> some View {
    ZStack {
      if let data = note.imageData, let image = UIImage(data: data) {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: width, height: height)
          .clipped()
      } else {
        Color.gray100
      }

      if extraCount > 0 {
        Color.black.opacity(0.45)
        Text("+\(extraCount)")
          .typeStyle(.title3)
          .foregroundStyle(.white)
      }
    }
    .frame(width: width, height: height)
    .contentShape(Rectangle())
    .onTapGesture {
      onShowPhoto?(note)
    }
    .accessibilityElement()
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel(extraCount > 0 ? "사진 \(extraCount)장 더 보기" : "사진 크게 보기")
  }
}
