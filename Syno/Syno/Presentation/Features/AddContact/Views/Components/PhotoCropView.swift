//
//  PhotoCropView.swift
//  Syno
//
//  Created by Codex on 7/28/26.
//

import SwiftUI
import UIKit

/// 프로필 이미지에 사용할 스퀴클 영역을 조정하고 결과 이미지를 렌더링하는 화면입니다.
struct PhotoCropView: View {
  @Environment(\.dismiss) private var dismiss

  let image: UIImage
  let onComplete: (Data) -> Void

  @State private var scale: CGFloat = 1
  @State private var settledScale: CGFloat = 1
  @State private var offset: CGSize = .zero
  @State private var settledOffset: CGSize = .zero
  @State private var toast: Toast?

  var body: some View {
    NavigationStack {
      GeometryReader { proxy in
        let cropSize = min(proxy.size.width - 48, 320)

        VStack(spacing: 0) {
          Spacer(minLength: 24)

          cropCanvas(cropSize: cropSize)

          Spacer(minLength: 24)

          Text("드래그로 위치, 두 손가락으로 확대/축소할 수 있어요")
            .typeStyle(.subheadline)
            .foregroundStyle(.gray500)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray50)
        .toast(item: $toast)
        .navigationTitle("사진 조정하기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button(action: dismiss.callAsFunction) {
              Image(systemName: "chevron.left")
                .foregroundStyle(.black)
            }
          }

          ToolbarItem(placement: .topBarTrailing) {
            Button("완료") {
              completeCropping(cropSize: cropSize)
            }
          }
        }
      }
    }
  }

  private func cropCanvas(cropSize: CGFloat) -> some View {
    let displayedSize = displayedImageSize(for: cropSize)

    return ZStack {
      Image(uiImage: image)
        .resizable()
        .frame(width: displayedSize.width, height: displayedSize.height)
        .offset(offset)
    }
    .frame(width: cropSize, height: cropSize)
    .clipShape(RoundedRectangle(cornerRadius: cropSize * 0.267, style: .continuous))
    .contentShape(Rectangle())
    .gesture(dragGesture(cropSize: cropSize))
    .simultaneousGesture(magnificationGesture(cropSize: cropSize))
    .accessibilityLabel("프로필 사진 크롭 영역")
  }

  private func dragGesture(cropSize: CGFloat) -> some Gesture {
    DragGesture()
      .onChanged { value in
        offset = clampedOffset(
          CGSize(
            width: settledOffset.width + value.translation.width,
            height: settledOffset.height + value.translation.height
          ),
          cropSize: cropSize
        )
      }
      .onEnded { _ in
        settledOffset = offset
      }
  }

  private func magnificationGesture(cropSize: CGFloat) -> some Gesture {
    MagnificationGesture()
      .onChanged { value in
        scale = min(max(settledScale * value, 1), 5)
        offset = clampedOffset(offset, cropSize: cropSize)
      }
      .onEnded { _ in
        settledScale = scale
        offset = clampedOffset(offset, cropSize: cropSize)
        settledOffset = offset
      }
  }

  private func displayedImageSize(for cropSize: CGFloat) -> CGSize {
    let imageSize = image.size
    guard imageSize.width > 0, imageSize.height > 0 else {
      return .zero
    }

    let minimumScale = max(cropSize / imageSize.width, cropSize / imageSize.height)
    return CGSize(
      width: imageSize.width * minimumScale * scale,
      height: imageSize.height * minimumScale * scale
    )
  }

  private func clampedOffset(_ proposedOffset: CGSize, cropSize: CGFloat) -> CGSize {
    let displayedSize = displayedImageSize(for: cropSize)
    let maximumX = max((displayedSize.width - cropSize) / 2, 0)
    let maximumY = max((displayedSize.height - cropSize) / 2, 0)

    return CGSize(
      width: min(max(proposedOffset.width, -maximumX), maximumX),
      height: min(max(proposedOffset.height, -maximumY), maximumY)
    )
  }

  private func completeCropping(cropSize: CGFloat) {
    guard let data = renderCroppedImage(cropSize: cropSize) else {
      toast = Toast(message: "사진을 조정하지 못했습니다.", style: .failure)
      return
    }

    onComplete(data)
    dismiss()
  }

  private func renderCroppedImage(cropSize: CGFloat) -> Data? {
    let outputSize = CGSize(width: 1024, height: 1024)
    let displayedSize = displayedImageSize(for: cropSize)
    guard displayedSize.width > 0, displayedSize.height > 0 else {
      return nil
    }

    let outputScale = outputSize.width / cropSize
    let imageRect = CGRect(
      x: (outputSize.width - displayedSize.width * outputScale) / 2 + offset.width * outputScale,
      y: (outputSize.height - displayedSize.height * outputScale) / 2 + offset.height * outputScale,
      width: displayedSize.width * outputScale,
      height: displayedSize.height * outputScale
    )
    let rendererFormat = UIGraphicsImageRendererFormat.default()
    rendererFormat.scale = 1
    rendererFormat.opaque = true

    let renderer = UIGraphicsImageRenderer(size: outputSize, format: rendererFormat)
    let croppedImage = renderer.image { _ in
      image.draw(in: imageRect)
    }
    return croppedImage.jpegData(compressionQuality: 0.9)
  }
}

/// 카메라/앨범에서 고른 이미지를 ``PhotoCropView``로 넘길 때 쓰는 식별 가능한 요청입니다.
struct PhotoCropRequest: Identifiable {
  let id = UUID()
  let image: UIImage
}
