import SwiftUI

/// 노트 필터 칩을 가로로 나열하고, 선택한 칩이 가운데로 오도록 자동 스크롤하는 줄입니다.
struct NoteFilterChipBar: View {
  let filters: [NoteFilter]
  let selectedFilter: NoteFilter
  let onSelect: (NoteFilter) -> Void

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(filters, id: \.self) { filter in
            NoteFilterChip(
              title: filter.title,
              isSelected: selectedFilter == filter
            ) {
              onSelect(filter)
            }
            .id(filter)
          }
        }
      }
      .scrollClipDisabled()
      .onChange(of: selectedFilter) { _, filter in
        withAnimation(.easeInOut(duration: 0.25)) {
          proxy.scrollTo(filter, anchor: .center)
        }
      }
    }
  }
}
