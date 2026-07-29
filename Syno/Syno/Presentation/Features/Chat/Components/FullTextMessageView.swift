import SwiftUI
import UIKit

/// 긴 메시지의 전체 내용을 표시하는 라지 시트 화면입니다.
struct FullTextMessageView: View {
  @Environment(\.dismiss) private var dismiss
  let note: Note
  let onDelete: (Note) -> Bool

  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?

  var body: some View {
    NavigationStack {
      ScrollView {
        Text(note.content)
          .typeStyle(.body)
          .foregroundStyle(.gray950)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(20)
          .background(.white)
          .clipShape(RoundedRectangle(cornerRadius: 20))
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 28)
      }
      .background(Color.gray50)
      .navigationTitle("메시지 전체보기")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Button {
              UIPasteboard.general.string = note.content
            } label: {
              Label("복사하기", systemImage: "doc.on.doc")
            }

            ShareLink(item: note.content) {
              Label("공유하기", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
              requestDeleteConfirmation()
            } label: {
              Label("삭제하기", systemImage: "trash")
            }
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
    }
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
  }

  private func requestDeleteConfirmation() {
    confirmationAlert = DestructiveConfirmationAlert(
      title: "이 메시지를\n삭제하겠습니까?",
      message: "삭제한 메시지는 복구할 수 없습니다.",
      acknowledgementText: nil
    ) {
      if onDelete(note) {
        dismiss()
      } else {
        toast = Toast(message: "메시지 삭제 실패했습니다", style: .failure)
      }
    }
  }
}
