//
//  OnboardingStartView.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 앱을 처음 실행한 사용자가 게스트 온보딩을 시작하는 화면입니다.
struct OnboardingStartView: View {
  let userProfileRepository: any UserProfileRepository

  var body: some View {
    VStack(spacing: 0) {
      Spacer()


        Image(.logo)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 300, height: 300)
      

      Spacer()

      NavigationLink {
        OnboardingBasicInfoView(repository: userProfileRepository)
      } label: {
        Text("시작하기")
          .typeStyle(.headline)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity, minHeight: 58)
          .background(.violet500)
          .clipShape(Capsule())
          .contentShape(Capsule())
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 20)

      consentFooter
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
    .background(.white)
    .navigationBarBackButtonHidden()
  }

  private var consentFooter: some View {
    HStack(spacing: 0) {
      Text("시작시 Syno의 ")

      NavigationLink {
        LegalDocumentView(title: "서비스 이용약관", content: Constants.AppInfo.termsOfService)
      } label: {
        Text("서비스 약관").underline()
      }

      Text("과 ")

      NavigationLink {
        LegalDocumentView(title: "개인정보 처리방침", content: Constants.AppInfo.privacyPolicy)
      } label: {
        Text("개인정보 보호정책").underline()
      }

      Text("에 동의합니다.")
    }
    .typeStyle(.caption1)
    .foregroundStyle(.gray500)
    .frame(maxWidth: .infinity)
  }
}

#Preview {
  NavigationStack {
    OnboardingStartView(userProfileRepository: PreviewRepositories.userProfile)
  }
}
