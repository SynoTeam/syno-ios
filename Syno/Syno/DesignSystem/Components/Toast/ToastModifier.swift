import SwiftUI

private struct ToastModifier: ViewModifier {
  @Binding var item: Toast?

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .top) {
        if let item {
          ToastView(
            toast: item,
            onAction: {
              performAction(for: item)
            }
          )
          .padding(.horizontal, 16)
          .padding(.top, 12)
          .transition(
            .move(edge: .top)
              .combined(with: .opacity)
          )
          .zIndex(1)
        }
      }
      .animation(
        .spring(response: 0.32, dampingFraction: 0.86),
        value: item?.id
      )
      .task(id: item?.id) {
        await dismissAfterDelay()
      }
  }

  private func dismissAfterDelay() async {
    guard let presentedToast = item else {
      return
    }

    do {
      try await Task.sleep(
        for: .seconds(max(presentedToast.duration, 0))
      )
    } catch {
      return
    }

    guard item?.id == presentedToast.id else {
      return
    }

    withAnimation {
      item = nil
    }
  }

  private func performAction(for toast: Toast) {
    guard item?.id == toast.id else {
      return
    }

    withAnimation {
      item = nil
    }
    toast.action?.handler()
  }
}

extension View {
  func toast(item: Binding<Toast?>) -> some View {
    modifier(ToastModifier(item: item))
  }
}
