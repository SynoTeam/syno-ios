import SwiftUI
import UIKit

/// 보내기 전에 확인할 사진 묶음입니다. 카메라는 1장, 앨범은 여러 장일 수 있습니다.
/// 원본을 들고 있지 않고 미리 줄여 둔 사진(`PreparedPhoto`)만 가집니다.
struct PhotoConfirmationRequest: Identifiable {
  let id = UUID()
  let photos: [PreparedPhoto]
}

/// 카메라/앨범에서 고른 사진을 보내기 전에 미리 보여주고 확인/취소를 받는 시트입니다.
/// 다른 바텀시트들과 같은 ``AddContactSheetHeader``(X/체크)를 재사용합니다.
/// 여러 장이면 옆으로 넘겨 보며, 확인하면 모두 순서대로 전송합니다.
struct ChatPhotoConfirmationView: View {
  @Environment(\.dismiss) private var dismiss

  let photos: [PreparedPhoto]
  let onSend: ([Data]) -> Void

  private var images: [UIImage] {
    photos.map(\.thumbnail)
  }

  var body: some View {
    VStack(spacing: 0) {
      AddContactSheetHeader(
        title: images.count > 1 ? "\(images.count)장" : "",
        onCancel: { dismiss() },
        onApply: send
      )

      photos
        .frame(maxHeight: .infinity)
    }
    .padding(.top, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray50)
  }

  @ViewBuilder
  private var photos: some View {
    if images.count > 1 {
      TabView {
        ForEach(images.indices, id: \.self) { index in
          photo(images[index])
            .padding(.bottom, 32)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .always))
    } else if let image = images.first {
      photo(image)
    }
  }

  // Figma처럼 사진을 시트 중앙에 높이 284pt 이내로 작게 보여준다. 가로세로 비율은 유지한다.
  private func photo(_ image: UIImage) -> some View {
    Image(uiImage: image)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(maxHeight: 284)
      .clipShape(RoundedRectangle(cornerRadius: 20))
      .padding(.horizontal, 32)
      .frame(maxHeight: .infinity)
  }

  private func send() {
    // 이미 줄여 둔 JPEG 데이터를 그대로 넘기므로 여기서는 무거운 변환을 하지 않는다.
    onSend(photos.map(\.imageData))
    dismiss()
  }
}
