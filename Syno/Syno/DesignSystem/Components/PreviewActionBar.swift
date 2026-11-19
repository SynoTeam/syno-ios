import SwiftUI

/// 사진·파일 미리보기 아래에 놓는 버튼 바입니다 (#140).
/// 회색 캡슐 안에 원형 버튼을 27pt 간격으로 두고, 바는 내용 크기로 화면 가운데에 놓습니다.
/// 버튼의 동작은 화면이 정하고, 버튼 모양은 `PreviewActionIcon`을 label로 씁니다.
struct PreviewActionBar<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    HStack(spacing: 27) {
      content()
    }
    .padding(8)
    .background(.gray100, in: Capsule())
    .frame(maxWidth: .infinity)
  }
}

/// `PreviewActionBar` 안의 버튼 모양입니다. 그림자 없는 44pt 흰 원 안에 24pt 아이콘을 둡니다.
/// `Button`, `ShareLink`, `Menu`의 label로 쓰고, 버튼 스타일은 `.plain`으로 둡니다.
struct PreviewActionIcon: View {
  let icon: ImageResource

  init(_ icon: ImageResource) {
    self.icon = icon
  }

  var body: some View {
    Image(icon)
      .resizable()
      .renderingMode(.template)
      .foregroundStyle(.gray600)
      .frame(width: 24, height: 24)
      .frame(width: 44, height: 44)
      .background(.white, in: Circle())
      .contentShape(Circle())
  }
}

#Preview {
  PreviewActionBar {
    PreviewActionIcon(.download)
    PreviewActionIcon(.share)
    PreviewActionIcon(.copy)
    PreviewActionIcon(.trash)
  }
  .padding()
  .background(Color.gray50)
}
