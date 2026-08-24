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
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("최근 검색어")
            .typeStyle(.footnote)
            .foregroundStyle(.gray500)

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
                Text(search)
                  .typeStyle(.calloutEmphasized)
                  .foregroundStyle(.gray800)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .contentShape(Rectangle())
              }
              .buttonStyle(.plain)

              Button {
                onDelete(search)
              } label: {
                Image(.xCircle)
                  .renderingMode(.template)
                  .foregroundStyle(.gray300)
                  .frame(width: 22, height: 22)
              }
              .buttonStyle(.plain)
              .accessibilityLabel("\(search) 삭제")
            }
            .frame(minHeight: 36)
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 16)
      .padding(.bottom, 12)
      .frame(maxWidth: .infinity, alignment: .topLeading)
      .background(.white)
      .cornerRadius(20)
      .padding(.horizontal, 16)
      .padding(.top, 16)
      .padding(.bottom, 120)
    }
  }
}
