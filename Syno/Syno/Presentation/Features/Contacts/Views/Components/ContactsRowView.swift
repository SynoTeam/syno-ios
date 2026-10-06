//
//  ContactsRowView.swift
//  Syno
//
//  Created by 이승진 on 7/16/26.
//

import SwiftUI
import UIKit

struct ContactsRowView: View {
  let name: String
  let group: String
  let profileImageData: Data?
  let style: Style

  init(
    name: String = "Sample User",
    group: String = "Design Team",
    profileImageData: Data? = nil,
    style: Style = .contact
  ) {
    self.name = name
    self.group = group
    self.profileImageData = profileImageData
    self.style = style
  }

  var body: some View {
    HStack(spacing: 12) {
      profileImage
      infoText
      Spacer()
    }
    .padding(.horizontal, style.horizontalPadding)
    .padding(.vertical, style.verticalPadding)
    .frame(maxWidth: .infinity, minHeight: style.minHeight)
    .modifier(RowSurface(style: style))
  }

  private var profileImage: some View {
    Group {
      if
        let profileImageData,
        let uiImage = UIImage(data: profileImageData)
      {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 44, height: 44)
      } else {
        InitialAvatar(name: name, size: 44, cornerRadius: 12)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  private var infoText: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(name)
        .typeStyle(.callout)
        .foregroundStyle(style.nameColor)
        .lineLimit(1)
        .truncationMode(.tail)

      if !group.isEmpty {
        Text(group)
          .typeStyle(.footnote)
          .foregroundStyle(style.metaColor)
          .lineLimit(1)
          .truncationMode(.tail)
      }
    }
  }

  enum Style {
    case me
    case contact

    var nameColor: Color {
      switch self {
      case .me:
          .gray950
      case .contact:
          .gray950
      }
    }

    var metaColor: Color {
      switch self {
      case .me:
          .gray500
      case .contact:
          .gray400
      }
    }

    var cornerRadius: CGFloat {
      switch self {
      case .me:
        20
      case .contact:
        0
      }
    }

    var horizontalPadding: CGFloat {
      switch self {
      case .me:
        12
      case .contact:
        8
      }
    }

    var minHeight: CGFloat {
      switch self {
      case .me:
        68
      case .contact:
        60
      }
    }

    var verticalPadding: CGFloat {
      switch self {
      case .me:
        4
      case .contact:
        0
      }
    }
  }
}

/// 행 배경입니다. `.me`는 이미지 위에 Glass 효과를 얹고, `.contact`는 흰색입니다.
private struct RowSurface: ViewModifier {
  let style: ContactsRowView.Style

  func body(content: Content) -> some View {
    let shape = RoundedRectangle(cornerRadius: style.cornerRadius)

    switch style {
    case .me:
      content
        .background(
          Image(.bgProfile)
            .resizable()
            .scaledToFill()
        )
        .clipShape(shape)
        .glassEffect(.regular, in: shape)
        // Glass 기본 바깥 그림자가 과해서 박스 밖으로 퍼지는 부분을 잘라낸다.
        .clipShape(shape)
        // 가장자리 안쪽으로 번지는 옅은 그림자(inner shadow)
        .overlay {
          shape
            .stroke(Color.violet300.opacity(0.35), lineWidth: 6)
            .blur(radius: 5)
            .offset(y: -2)
            .clipShape(shape)
            .allowsHitTesting(false)
        }

    case .contact:
      content
        .background(Color.white)
        .clipShape(shape)
    }
  }
}

#Preview {
  ContactsRowView()
}
