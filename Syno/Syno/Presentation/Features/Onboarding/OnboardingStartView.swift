//
//  OnboardingStartView.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 앱을 처음 실행한 사용자가 게스트 온보딩을 시작하는 화면입니다.
struct OnboardingStartView: View {
  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: 24) {
        Image(.logo)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 112, height: 112)

        Text("Syno")
          .typeStyle(.largeTitle)
          .foregroundStyle(.gray950)
      }

      Spacer()

      NavigationLink {
        OnboardingBasicInfoView()
      } label: {
        Text("게스트로 시작하기")
          .typeStyle(.headline)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity, minHeight: 58)
          .background(.violet500)
          .clipShape(Capsule())
          .contentShape(Capsule())
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 20)
      .padding(.bottom, 36)
    }
    .background(Color.gray50)
    .navigationBarBackButtonHidden()
  }
}

#Preview {
  NavigationStack {
    OnboardingStartView()
  }
}
