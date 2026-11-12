//
//  ShareContactRowView.swift
//  SynoShareExtension
//

import SwiftUI
import UIKit

/// 공유 화면의 연락처 행입니다. 왼쪽 선택 원과 흰 카드(프로필, 이름, 최근 노트 한 줄)로 이뤄집니다.
/// 앱의 노트 선택 삭제 행과 같은 모양이고, 시간은 표시하지 않습니다.
struct ShareContactRowView: View {
  let row: ShareContactRow
  let isSelected: Bool
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 12) {
        selectionIndicator

        HStack(spacing: 12) {
          profileImage

          VStack(alignment: .leading, spacing: 2) {
            Text(row.name)
              .typeStyle(.callout)
              .foregroundStyle(.gray950)
              .lineLimit(1)
              .truncationMode(.tail)

            if !row.subtitle.isEmpty {
              Text(row.subtitle)
                .typeStyle(.footnote)
                .foregroundStyle(.gray500)
                .lineLimit(1)
                .truncationMode(.tail)
            }
          }

          Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(accessibilityLabel)
  }

  /// 이름이 같은 연락처도 구분할 수 있게 두 번째 줄을 함께 읽어 줍니다.
  private var accessibilityLabel: String {
    let selection = isSelected ? "선택됨" : "선택 안 됨"
    guard !row.subtitle.isEmpty else { return "\(row.name), \(selection)" }
    return "\(row.name), \(row.subtitle), \(selection)"
  }

  private var selectionIndicator: some View {
    Group {
      if isSelected {
        Image(.checkCircleFilled)
          .resizable()
          .renderingMode(.template)
          .foregroundStyle(.gray900)
      } else {
        Circle()
          .stroke(Color.gray300, lineWidth: 1.5)
          .padding(2)
      }
    }
    .frame(width: 28, height: 28)
  }

  private var profileImage: some View {
    Group {
      if let data = row.profileImageData, let uiImage = UIImage(data: data) {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 44, height: 44)
      } else {
        InitialAvatar(name: row.name, size: 44, cornerRadius: 12)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}
