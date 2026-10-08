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
    // 최근 검색어가 없으면 아무것도 표시하지 않는다(빈 화면).
    if !searches.isEmpty {
      scrollContent
    }
  }

  private var scrollContent: some View {
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

        // 검색어 행끼리는 붙이고, 헤더와 첫 검색어 사이만 바깥 간격(8)을 쓴다.
        VStack(spacing: 0) {
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
                  .resizable()
                  .renderingMode(.template)
                  .foregroundStyle(.gray300)
                  .frame(width: 16, height: 16)
                  // 아이콘은 16pt로 보이되 터치 영역은 위아래로 넓힌다.
                  .padding(.vertical, 10)
                  .contentShape(Rectangle())
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
    // 내용이 화면보다 짧으면 끌어도 움직이지 않게 해서 위쪽 16pt 위치를 고정한다.
    .scrollBounceBehavior(.basedOnSize)
  }
}
