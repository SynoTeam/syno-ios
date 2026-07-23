//
//  RecentSearchesView.swift
//  Syno
//

import SwiftUI

struct RecentSearchesView: View {
  let searches: [String]
  let onSelect: (String) -> Void
  let onDelete: (String) -> Void
  let onClear: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("최근 검색어")
            .typeStyle(.headline)
            .foregroundStyle(.gray950)

          Spacer()

          if !searches.isEmpty {
            Button("전체 삭제", action: onClear)
              .typeStyle(.caption1)
              .foregroundStyle(.gray500)
          }
        }

        if searches.isEmpty {
          Text("최근 검색어가 없습니다.")
            .typeStyle(.body)
            .foregroundStyle(.gray400)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 72)
        } else {
          ForEach(searches, id: \.self) { search in
            HStack(spacing: 12) {
              Button {
                onSelect(search)
              } label: {
                HStack(spacing: 12) {
                  Image(systemName: "clock")
                    .foregroundStyle(.gray400)
                  Text(search)
                    .typeStyle(.body)
                    .foregroundStyle(.gray900)
                  Spacer()
                }
                .contentShape(Rectangle())
              }
              .buttonStyle(.plain)

              Button {
                onDelete(search)
              } label: {
                Image(systemName: "xmark")
                  .font(.system(size: 13, weight: .medium))
                  .foregroundStyle(.gray400)
                  .frame(width: 36, height: 36)
              }
              .buttonStyle(.plain)
              .accessibilityLabel("\(search) 삭제")
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 12)
      .padding(.bottom, 120)
    }
  }
}
