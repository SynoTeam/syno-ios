import SwiftUI

struct Toast: Identifiable {
  let id = UUID()
  let message: String
  let style: Style
  let icon: String?
  let duration: TimeInterval
  let action: Action?

  init(
    message: String,
    style: Style,
    icon: String? = nil,
    duration: TimeInterval = 2.5,
    action: Action? = nil
  ) {
    self.message = message
    self.style = style
    self.icon = icon
    self.duration = duration
    self.action = action
  }
}

extension Toast {
  enum Style {
    case success
    case failure
  }

  struct Action {
    let title: String
    let handler: @MainActor () -> Void

    init(
      title: String,
      handler: @escaping @MainActor () -> Void
    ) {
      self.title = title
      self.handler = handler
    }
  }
}

struct ToastView: View {
  let toast: Toast
  let onAction: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: toast.icon ?? toast.style.iconName)
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(toast.style.accentColor)
        .accessibilityHidden(true)

      Text(toast.message)
        .typeStyle(.subheadlineEmphasized)
        .foregroundStyle(.bgWhite)
        .frame(maxWidth: .infinity, alignment: .leading)
      
      Spacer()

      if let action = toast.action {
        Button(action: onAction) {
          Text(action.title)
            .typeStyle(.subheadlineEmphasized)
            .foregroundStyle(.gray100)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(height: 38, alignment: .center)
            .background(Color.gray800.opacity(0.8))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 5)
        .accessibilityHint("알림을 닫고 \(action.title) 작업을 실행합니다.")
      }
    }
    .padding(.leading, 18)
    .padding(.vertical, 14)
    .frame(height: 48)
    .glassEffect(.regular.tint(toast.style.backgroundColor), in: .capsule)
    .overlay {
      Capsule()
        .stroke(toast.style.accentColor.opacity(0.16), lineWidth: 1)
    }
    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    .accessibilityLabel(toast.message)
  }
}

private extension Toast.Style {
  var iconName: String {
    switch self {
    case .success:
      "checkmark.circle.fill"
    case .failure:
      "exclamationmark.circle.fill"
    }
  }

  var accentColor: Color {
    switch self {
    case .success:
      .violet200
    case .failure:
      .bgBlack
    }
  }

  var backgroundColor: Color {
    switch self {
    case .success:
        .gray800.opacity(0.8)
    case .failure:
        .errorRed.opacity(0.4)
    }
  }
}

#Preview("Toast states") {
  ToastPreview()
}

private struct ToastPreview: View {
  @State private var toast: Toast?
  @State private var status = "액션 대기 중"

  var body: some View {
    VStack(spacing: 16) {
      Text(status)
        .typeStyle(.body)

      Button("성공 Toast") {
        toast = Toast(
          message: "연락처를 저장했습니다.",
          style: .success
        )
      }

      Button("실패 Toast") {
        toast = Toast(
          message: "저장하지 못했습니다.",
          style: .failure
        )
      }

      Button("되돌리기 Toast") {
        toast = Toast(
          message: "연락처를 삭제했습니다.",
          style: .success,
          icon: "trash.fill",
          action: Toast.Action(title: "되돌리기") {
            status = "삭제를 되돌렸습니다."
          }
        )
      }
    }
    .buttonStyle(.borderedProminent)
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray50)
    .toast(item: $toast)
  }
}
