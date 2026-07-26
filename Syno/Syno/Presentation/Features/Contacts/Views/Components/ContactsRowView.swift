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
  let role: String
  let company: String
  let profileImageData: Data?
  let style: Style

  init(
    name: String = "Sample User",
    role: String = "Product Designer",
    company: String = "@syno",
    profileImageData: Data? = nil,
    style: Style = .contact
  ) {
    self.name = name
    self.role = role
    self.company = company
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
    .frame(maxWidth: .infinity, minHeight: 60)
    .background(style.backgroundColor)
    .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
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
        RoundedRectangle(cornerRadius: 12)
          .fill(.gray100)
          .frame(width: 44, height: 44)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  private var infoText: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(name)
        .typeStyle(.callout)
        .foregroundStyle(style.nameColor)
      HStack(spacing: 6) {
        if !role.isEmpty {
          Text(role)
            .typeStyle(.footnote)
            .foregroundStyle(style.metaColor)
        }

        if !company.isEmpty {
          Text(company)
            .typeStyle(.footnote)
            .foregroundStyle(style.metaColor)
        }
      }
    }
  }

  enum Style {
    case me
    case contact

    var backgroundColor: Color {
      switch self {
      case .me:
          .gray800
      case .contact:
          .white
      }
    }

    var nameColor: Color {
      switch self {
      case .me:
          .gray25
      case .contact:
          .gray950
      }
    }

    var metaColor: Color {
      switch self {
      case .me:
          .gray300
      case .contact:
          .gray400
      }
    }

    var cornerRadius: CGFloat {
      switch self {
      case .me:
        24
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

#Preview {
  ContactsRowView()
}
