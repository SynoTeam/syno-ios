import SwiftUI
import UIKit

/// 카메라/앨범에서 고른 사진을 보내기 전에 미리 보여주고 확인/취소를 받는 시트입니다.
/// 다른 바텀시트들과 같은 ``AddContactSheetHeader``(X/체크)를 재사용합니다.
struct ChatPhotoConfirmationView: View {
  @Environment(\.dismiss) private var dismiss

  let image: UIImage
  let onSend: (Data) -> Void

  var body: some View {
    VStack(spacing: 0) {
      AddContactSheetHeader(title: "", onCancel: { dismiss() }, onApply: send)

      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 32)
        .frame(maxHeight: .infinity)
    }
    .padding(.top, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray50)
  }

  private func send() {
    guard let data = image.jpegData(compressionQuality: 0.9) else {
      dismiss()
      return
    }
    onSend(data)
    dismiss()
  }
}
