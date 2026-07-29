//
//  OnboardingBasicInfoView.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 온보딩에서 사용자 이름의 기본 정보를 입력받는 화면입니다.
struct OnboardingBasicInfoView: View {
  @FocusState private var focusedField: Field?
  @State private var viewModel: OnboardingBasicInfoViewModel

  init(repository: any UserProfileRepository) {
    _viewModel = State(
      initialValue: OnboardingBasicInfoViewModel(repository: repository)
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("기본 정보를 알려주세요")
        .typeStyle(.title2Emphasized)
        .foregroundStyle(.gray950)
        .padding(.top, 36)
        .padding(.bottom, 46)

      VStack(alignment: .leading, spacing: 32) {
        onboardingTextField(
          title: "성/ Surname",
          placeholder: "홍",
          text: binding(\.familyName),
          field: .familyName
        ) {
          focusedField = .givenName
        }

        onboardingTextField(
          title: "이름/ Given Name",
          placeholder: "길동",
          text: binding(\.givenName),
          field: .givenName,
          submitLabel: .done
        ) {
          focusedField = nil
        }
      }

      Spacer()

      Button(action: viewModel.saveUserProfile) {
        Text("확인")
          .typeStyle(.headline)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity, minHeight: 60)
          .background(viewModel.canSubmit ? .violet500 : .violet200)
          .clipShape(Capsule())
          .contentShape(Capsule())
      }
      .buttonStyle(.plain)
      .disabled(!viewModel.canSubmit)
      .padding(.bottom, 36)
    }
    .padding(.horizontal, 20)
    .background(Color.gray50)
    .scrollDismissesKeyboard(.interactively)
    .dismissKeyboardOnTap($focusedField)
    .navigationBarTitleDisplayMode(.inline)
    .alert("오류", isPresented: persistenceErrorBinding) {
      Button("확인", action: viewModel.clearPersistenceError)
    } message: {
      Text(viewModel.persistenceError ?? "")
    }
  }

  private func onboardingTextField(
    title: String,
    placeholder: String,
    text: Binding<String>,
    field: Field,
    submitLabel: SubmitLabel = .next,
    onSubmit: @escaping () -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .typeStyle(.subheadlineEmphasized)
        .foregroundStyle(.gray500)

      TextField(placeholder, text: text)
        .typeStyle(.body)
        .foregroundStyle(.gray950)
        .frame(height: 62)
        .padding(.horizontal, 24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .focused($focusedField, equals: field)
        .submitLabel(submitLabel)
        .onSubmit(onSubmit)
    }
  }

  private func binding<Value>(
    _ keyPath: ReferenceWritableKeyPath<OnboardingBasicInfoViewModel, Value>
  ) -> Binding<Value> {
    Binding(
      get: { viewModel[keyPath: keyPath] },
      set: { viewModel[keyPath: keyPath] = $0 }
    )
  }

  private var persistenceErrorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.persistenceError != nil },
      set: { isPresented in
        if !isPresented {
          viewModel.clearPersistenceError()
        }
      }
    )
  }

  private enum Field: Hashable {
    case familyName
    case givenName
  }
}

#Preview {
  NavigationStack {
    OnboardingBasicInfoView(repository: PreviewRepositories.userProfile)
  }
}
