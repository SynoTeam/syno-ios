//
//  OnboardingBasicInfoView.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftData
import SwiftUI

/// 온보딩에서 사용자 이름의 기본 정보를 입력받는 화면입니다.
struct OnboardingBasicInfoView: View {
  @Environment(\.modelContext) private var modelContext
  @FocusState private var focusedField: Field?
  @State private var viewModel = OnboardingBasicInfoViewModel()

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("기본 정보를 알려주세요")
        .typeStyle(.header)
        .foregroundStyle(.gray950)
        .padding(.top, 76)
        .padding(.bottom, 72)

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

      Button(action: saveUserProfile) {
        Text("확인")
          .typeStyle(.headline)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity, minHeight: 58)
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
        .typeStyle(.subheadline)
        .foregroundStyle(.gray500)

      TextField(placeholder, text: text)
        .typeStyle(.body)
        .foregroundStyle(.gray950)
        .frame(height: 58)
        .padding(.horizontal, 24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
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

  private func saveUserProfile() {
    modelContext.insert(viewModel.makeUserProfile())
    try? modelContext.save()
  }

  private enum Field: Hashable {
    case familyName
    case givenName
  }
}

#Preview {
  NavigationStack {
    OnboardingBasicInfoView()
  }
}
