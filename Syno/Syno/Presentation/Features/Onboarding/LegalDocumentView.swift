import SwiftUI

/// 약관/개인정보처리방침 등 텍스트 형태의 법적 문서를 보여주는 화면입니다.
struct LegalDocumentView: View {
  let title: String
  let content: String

  var body: some View {
    ScrollView {
      Text(attributedContent)
        .typeStyle(.body)
        .foregroundStyle(.gray900)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
    .background(Color.gray50)
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .synoBackButton()
    // 앱 설정에서 열릴 때 탭바가 다시 나타나지 않도록 한다. 온보딩에는 탭바가 없어 영향이 없다.
    .toolbar(.hidden, for: .tabBar)
  }

  private var attributedContent: AttributedString {
    (try? AttributedString(markdown: content)) ?? AttributedString(content)
  }
}

#Preview {
  NavigationStack {
    LegalDocumentView(title: "이용약관", content: Constants.AppInfo.termsOfService)
  }
}
