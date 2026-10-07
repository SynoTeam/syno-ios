import SwiftUI

/// 탭 루트 화면(Contacts, Notes) 상단에 쓰는 제목 + 우측 액션 헤더입니다.
struct TabRootHeader<Trailing: View>: View {
  let title: String
  private let trailing: () -> Trailing

  init(title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
    self.title = title
    self.trailing = trailing
  }

  var body: some View {
    HStack {
      Text(title)
        .typeStyle(.header)
        .foregroundStyle(.neutral900)

      Spacer()

      trailing()
    }
    .frame(height: 60)
  }
}

/// 헤더 우측에 놓는 44pt 흰색 원형 아이콘입니다. `Menu`/`Button`의 label로 사용합니다.
struct HeaderCircleIcon: View {
  let icon: ImageResource

  init(_ icon: ImageResource) {
    self.icon = icon
  }

  var body: some View {
    Image(icon)
      .resizable()
      .renderingMode(.template)
      .foregroundStyle(.gray900)
      .frame(width: 22, height: 22)
      .frame(width: 44, height: 44)
      .glassEffect(.regular.interactive(), in: .circle)
  }
}

#Preview {
  TabRootHeader(title: "Notes") {
    HeaderCircleIcon(.moreHorizontal)
  }
  .padding()
  .background(Color.gray50)
}
