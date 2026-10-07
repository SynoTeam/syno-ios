import SwiftUI

/// 프로필 사진이 없을 때 이름의 첫 글자를 보여주는 기본 아바타입니다.
struct InitialAvatar: View {
  let name: String
  let size: CGFloat
  let cornerRadius: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(.violet100)
      .frame(width: size, height: size)
      .overlay {
        if let initial {
          Text(initial)
            .font(.custom("Pretendard-SemiBold", fixedSize: size * 0.4))
            .foregroundStyle(.violet600)
        } else {
          Image(.person)
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(.violet600)
            .frame(width: size * 0.4, height: size * 0.4)
        }
      }
      .accessibilityHidden(true)
  }

  private var initial: String? {
    name
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .first
      .map { String($0).uppercased() }
  }
}

#Preview {
  HStack(spacing: 12) {
    InitialAvatar(name: "김시노", size: 44, cornerRadius: 12)
    InitialAvatar(name: "Hana Moon", size: 44, cornerRadius: 12)
    InitialAvatar(name: "", size: 44, cornerRadius: 12)
    InitialAvatar(name: "김시노", size: 96, cornerRadius: 25.6)
  }
  .padding()
}
