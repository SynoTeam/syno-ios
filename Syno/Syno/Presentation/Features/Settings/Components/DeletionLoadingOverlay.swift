//
//  DeletionLoadingOverlay.swift
//  Syno
//
//  Created by Codex on 7/28/26.
//

import SwiftUI

/// 데이터 삭제 중에는 화면 조작을 막고 진행 상태를 알려주는 전체 화면 오버레이입니다.
struct DeletionLoadingOverlay: View {
  /// 진행 중인 작업을 알리는 문구입니다. 삭제와 로그아웃이 같은 오버레이를 씁니다.
  var message = "삭제 중"

  @State private var isAnimating = false

  var body: some View {
    ZStack {
      Color.black.opacity(0.28)
        .ignoresSafeArea()

      VStack(spacing: 18) {
        Circle()
          .fill(
            LinearGradient(
              colors: [Color.gradient02, Color.gradient03],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 68, height: 68)
          .scaleEffect(isAnimating ? 1.06 : 0.94)

        Text(message)
          .typeStyle(.headline)
          .foregroundStyle(.gray950)
      }
      .padding(.horizontal, 42)
      .padding(.vertical, 30)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
      .shadow(color: .black.opacity(0.16), radius: 24, y: 10)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(message)
    .onAppear {
      withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
        isAnimating = true
      }
    }
  }
}

#Preview {
  DeletionLoadingOverlay()
}
