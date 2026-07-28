//
//  NoteRowView.swift
//  Syno
//
//  Created by 이승진 on 7/19/26.
//

import SwiftUI
import UIKit

/// 노트 목록에서 연락처 이미지, 이름, 내용, 시간을 표시하는 row입니다.
struct NoteRowView: View {
  let note: Note

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      profileImage

      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          if note.isPinned {
            Image(systemName: "pin.fill")
              .font(.system(size: 11, weight: .semibold))
              .foregroundStyle(.violet500)
              .accessibilityLabel("고정된 노트")
          }

          Text(note.contactName)
            .typeStyle(.callout)
            .foregroundStyle(.gray950)
            .lineLimit(1)
            .truncationMode(.tail)

          Spacer(minLength: 8)

          Text(note.timeText)
            .typeStyle(.caption1)
            .foregroundStyle(.gray400)
            .lineLimit(1)
        }

        Text(note.content)
          .typeStyle(.footnote)
          .foregroundStyle(.gray500)
          .lineLimit(1)
          .truncationMode(.tail)
      }
      .padding(.top, 3)
    }
    .padding(13)
    .frame(maxWidth: .infinity, minHeight: 70)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }

  private var profileImage: some View {
    Group {
      if
        let imageData = note.imageData,
        let uiImage = UIImage(data: imageData)
      {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 44, height: 44)
      } else if
        let profileImageData = note.profileImageData,
        let uiImage = UIImage(data: profileImageData)
      {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 44, height: 44)
      } else {
        RoundedRectangle(cornerRadius: 12)
          .fill(.gray100)
          .frame(width: 44, height: 44)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}
