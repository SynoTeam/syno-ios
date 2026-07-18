//
//  Image+Profile.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI
import UIKit

extension Image {
  /// 프로필 이미지 데이터를 우선 표시하고, 데이터가 없으면 회색 placeholder를 표시합니다.
  func profileImage(data: Data?, size: CGFloat) -> some View {
    Group {
      if
        let data,
        let uiImage = UIImage(data: data)
      {
        Image(uiImage: uiImage)
          .resizable()
      } else {
        Circle()
          .fill(.gray100)
      }
    }
    .aspectRatio(contentMode: .fill)
    .frame(width: size, height: size)
    .clipShape(Circle())
  }
}
