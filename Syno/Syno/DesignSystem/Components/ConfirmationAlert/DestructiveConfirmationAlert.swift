import SwiftUI

struct DestructiveConfirmationAlert: Identifiable {
  let id = UUID()
  let title: String
  let message: String
  let acknowledgementText: String?
  let confirmTitle: String
  let onConfirm: () -> Void

  init(
    title: String,
    message: String,
    acknowledgementText: String? = "위 내용을 모두 확인했습니다.",
    confirmTitle: String = "삭제",
    onConfirm: @escaping () -> Void
  ) {
    self.title = title
    self.message = message
    self.acknowledgementText = acknowledgementText
    self.confirmTitle = confirmTitle
    self.onConfirm = onConfirm
  }
}

private struct DestructiveConfirmationAlertModifier: ViewModifier {
  @Binding var item: DestructiveConfirmationAlert?

  func body(content: Content) -> some View {
    content
      .overlay {
        if let item {
          DestructiveConfirmationAlertView(
            alert: item,
            onCancel: { self.item = nil },
            onConfirm: {
              let onConfirm = item.onConfirm
              self.item = nil
              onConfirm()
            }
          )
          .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
      }
      .animation(.easeOut(duration: 0.2), value: item?.id)
  }
}

extension View {
  func destructiveConfirmationAlert(item: Binding<DestructiveConfirmationAlert?>) -> some View {
    modifier(DestructiveConfirmationAlertModifier(item: item))
  }
}

private struct DestructiveConfirmationAlertView: View {
  let alert: DestructiveConfirmationAlert
  let onCancel: () -> Void
  let onConfirm: () -> Void

  @State private var hasAcknowledgedWarning = false

  private var isConfirmEnabled: Bool {
    alert.acknowledgementText == nil || hasAcknowledgedWarning
  }

  var body: some View {
    ZStack {
      Color.black.opacity(0.35)
        .ignoresSafeArea()
        .onTapGesture(perform: onCancel)

      VStack(spacing: 12) {
        Text(alert.title)
          .typeStyle(.headline)
          .foregroundStyle(.bgBlack)
          .multilineTextAlignment(.center)

        Text(alert.message)
          .typeStyle(.subheadline)
          .foregroundStyle(.gray800)
          .multilineTextAlignment(.center)

        if let acknowledgementText = alert.acknowledgementText {
          Button {
            hasAcknowledgedWarning.toggle()
          } label: {
            HStack(spacing: 8) {
              Image(systemName: hasAcknowledgedWarning ? "checkmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(hasAcknowledgedWarning ? .gray900 : .gray400)
              Text(acknowledgementText)
                .typeStyle(.callout)
                .foregroundStyle(.bgBlack)
            }
            .padding(.horizontal, 23)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.bgBlack.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 999))
          }
          .buttonStyle(PressScaleButtonStyle())
          .padding(.top, 4)
        }

        HStack(spacing: 12) {
          Button("취소", action: onCancel)
            .typeStyle(.headline)
            .foregroundStyle(.bgBlack)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(.gray500.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 100))
            .buttonStyle(PressScaleButtonStyle())

          Button {
            guard isConfirmEnabled else {
              return
            }
            onConfirm()
          } label: {
            Text(alert.confirmTitle)
              .typeStyle(.headline)
              .foregroundStyle(isConfirmEnabled ? .errorRed : .errorRed.opacity(0.67))
              .frame(maxWidth: .infinity, minHeight: 48)
              .background(isConfirmEnabled ? .errorRed.opacity(0.05) : .errorRed.opacity(0.03))
              .clipShape(RoundedRectangle(cornerRadius: 100))
          }
          .buttonStyle(PressScaleButtonStyle())
          .disabled(!isConfirmEnabled)
        }
      }
      .padding(22)
      .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28))
      .padding(.horizontal, 46)
    }
  }
}

private struct PressScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1)
      .opacity(configuration.isPressed ? 0.85 : 1)
      .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
  }
}

#Preview {
  DestructiveConfirmationAlertPreview()
}

private struct DestructiveConfirmationAlertPreview: View {
  @State private var alert: DestructiveConfirmationAlert?
  @State private var status = "대기 중"

  var body: some View {
    VStack(spacing: 16) {
      Text(status)
        .typeStyle(.body)

      Button("1건 삭제 알럿") {
        alert = DestructiveConfirmationAlert(
          title: "해당 연락처를\n영구적으로 삭제하겠습니까?",
          message: "연락처와 모든 노트와 파일이 삭제됩니다. 이 작업은 되돌릴 수 없습니다."
        ) {
          status = "1건 삭제됨"
        }
      }

      Button("3건 삭제 알럿") {
        alert = DestructiveConfirmationAlert(
          title: "해당 연락처 3건을\n영구적으로 삭제하겠습니까?",
          message: "연락처와 모든 노트와 파일이 삭제됩니다. 이 작업은 되돌릴 수 없습니다."
        ) {
          status = "3건 삭제됨"
        }
      }

      Button("체크박스 없는 알럿") {
        alert = DestructiveConfirmationAlert(
          title: "메모를 삭제하겠습니까?",
          message: "삭제한 메모는 복구할 수 없습니다.",
          acknowledgementText: nil
        ) {
          status = "메모 삭제됨"
        }
      }
    }
    .buttonStyle(.borderedProminent)
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray50)
    .destructiveConfirmationAlert(item: $alert)
  }
}
