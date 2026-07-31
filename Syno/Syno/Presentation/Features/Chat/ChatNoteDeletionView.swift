import SwiftUI

/// 채팅방의 여러 메시지를 선택해 삭제하는 push 화면입니다.
struct ChatNoteDeletionView: View {
  let viewModel: ChatViewModel
  let onDeleted: (Int) -> Void

  @State private var selectedNoteIDs: Set<Note.ID>
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?

  init(
    viewModel: ChatViewModel,
    initiallySelectedNoteID: Note.ID,
    onDeleted: @escaping (Int) -> Void
  ) {
    self.viewModel = viewModel
    self.onDeleted = onDeleted
    _selectedNoteIDs = State(initialValue: [initiallySelectedNoteID])
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 16) {
        ForEach(viewModel.messageSections) { section in
          Text(section.title)
            .typeStyle(.footnoteEmphasized)
            .foregroundStyle(.gray400)
            .padding(.horizontal, 8)

          VStack(spacing: 8) {
            ForEach(section.messages) { note in
              ChatNoteDeletionRow(
                note: note,
                isSelected: selectedNoteIDs.contains(note.id)
              ) {
                toggleSelection(for: note.id)
              }
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 28)
    }
    .background(Color.gray50)
    .navigationTitle("노트 삭제")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("완료", action: requestDeleteConfirmation)
          .disabled(selectedNoteIDs.isEmpty)
          .accessibilityLabel("선택한 노트 삭제")
      }
    }
    .onChange(of: viewModel.messages.map(\.id)) { _, messageIDs in
      selectedNoteIDs.formIntersection(Set(messageIDs))
    }
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
  }

  private func toggleSelection(for id: Note.ID) {
    if selectedNoteIDs.contains(id) {
      selectedNoteIDs.remove(id)
    } else {
      selectedNoteIDs.insert(id)
    }
  }

  private func requestDeleteConfirmation() {
    guard !selectedNoteIDs.isEmpty else {
      return
    }

    confirmationAlert = DestructiveConfirmationAlert(
      title: deleteConfirmationTitle,
      message: "삭제한 메시지는 복구할 수 없습니다.",
      acknowledgementText: nil
    ) {
      deleteSelectedNotes()
    }
  }

  private var deleteConfirmationTitle: String {
    selectedNoteIDs.count > 1
      ? "\(selectedNoteIDs.count)개의 노트를\n삭제하시겠습니까?"
      : "이 메시지를\n삭제하시겠습니까?"
  }

  private func deleteSelectedNotes() {
    let deletedCount = selectedNoteIDs.count
    guard viewModel.deleteMessages(ids: selectedNoteIDs) else {
      toast = Toast(message: "메시지 삭제 실패했습니다", style: .failure)
      return
    }

    onDeleted(deletedCount)
  }
}

private struct ChatNoteDeletionRow: View {
  let note: Note
  let isSelected: Bool
  let onToggle: () -> Void

  var body: some View {
    Button(action: onToggle) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(note.content)
            .typeStyle(.callout)
            .foregroundStyle(.gray950)
            .frame(maxWidth: .infinity, alignment: .leading)

          Text(note.clockTimeText)
            .typeStyle(.caption1)
            .foregroundStyle(.gray400)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(minHeight: 68, alignment: .topLeading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))

        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 24, weight: .medium))
          .foregroundStyle(isSelected ? .violet500 : .gray300)
          .padding(.top, 16)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(note.content), \(isSelected ? "선택됨" : "선택 안 됨")")
  }
}
