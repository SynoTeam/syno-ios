import SwiftUI

/// 제목 아래에 여러 선택지를 알약 버튼으로 나열하고, 아래에 취소 버튼을 두는 카드형 알럿입니다.
struct ActionChoiceAlert: Identifiable {
  struct Action: Identifiable {
    let id = UUID()
    let title: String
    let handler: () -> Void
  }

  let id = UUID()
  let title: String
  let actions: [Action]
}

private struct ActionChoiceAlertModifier: ViewModifier {
  @Binding var item: ActionChoiceAlert?

  /// 알럿이 완전히 닫힌 뒤에 실행할 선택지입니다. 닫히는 도중에 시트를 띄우면 무시되므로 미룹니다.
  @State private var pendingHandler: (() -> Void)?

  func body(content: Content) -> some View {
    content
      .fullScreenCover(
        item: $item,
        onDismiss: {
          let handler = pendingHandler
          pendingHandler = nil
          handler?()
        }
      ) { alert in
        ActionChoiceAlertView(alert: alert) { selected in
          pendingHandler = selected?.handler
          var transaction = Transaction()
          transaction.disablesAnimations = true
          withTransaction(transaction) {
            item = nil
          }
        }
        .presentationBackground(.clear)
      }
      // 풀스크린 커버가 아래에서 올라오지 않고 제자리에서 나타나게 한다.
      .transaction { $0.disablesAnimations = true }
  }
}

extension View {
  func actionChoiceAlert(item: Binding<ActionChoiceAlert?>) -> some View {
    modifier(ActionChoiceAlertModifier(item: item))
  }
}

private struct ActionChoiceAlertView: View {
  let alert: ActionChoiceAlert
  /// 선택지를 고르면 해당 선택지를, 취소하면 nil을 전달합니다.
  let onFinish: (ActionChoiceAlert.Action?) -> Void

  @State private var isVisible = false

  var body: some View {
    ZStack {
      Color.black.opacity(0.35)
        .ignoresSafeArea()
        .onTapGesture { onFinish(nil) }

      VStack(spacing: 8) {
        Text(alert.title)
          .typeStyle(.headline)
          .foregroundStyle(.bgBlack)
          .padding(.bottom, 4)

        ForEach(alert.actions) { action in
          pillButton(action.title) { onFinish(action) }
        }

        pillButton("취소") { onFinish(nil) }
      }
      .padding(22)
      .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28))
      .padding(.horizontal, 46)
    }
    .opacity(isVisible ? 1 : 0)
    .scaleEffect(isVisible ? 1 : 0.96)
    .onAppear {
      withAnimation(.easeOut(duration: 0.2)) {
        isVisible = true
      }
    }
  }

  private func pillButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .typeStyle(.callout)
        .foregroundStyle(.bgBlack)
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(.gray500.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 100))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
