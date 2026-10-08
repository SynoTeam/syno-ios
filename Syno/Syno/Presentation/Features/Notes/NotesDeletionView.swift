import SwiftUI

/// Notes 탭에서 여러 연락처의 노트를 골라 한 번에 삭제하는 push 화면입니다.
///
/// 목록의 한 행은 연락처의 최근 노트이며, 삭제하면 그 연락처에 저장된 노트와 파일이 모두 삭제됩니다.
struct NotesDeletionView: View {
  let viewModel: NotesViewModel
  /// 선택한 노트의 연락처 데이터를 삭제하고 성공 여부를 돌려줍니다.
  let onDelete: ([Note]) -> Bool
  let onDeleted: (Int) -> Void

  @State private var selectedNoteIDs: Set<Note.ID> = []
  @State private var confirmationAlert: DestructiveConfirmationAlert?
  @State private var toast: Toast?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        filterChips

        LazyVStack(spacing: 8) {
          ForEach(viewModel.filteredNotes) { note in
            NotesDeletionRow(
              note: note,
              isSelected: selectedNoteIDs.contains(note.id)
            ) {
              toggleSelection(for: note.id)
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 8)
      .padding(.bottom, 28)
    }
    .background(Color.gray50)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(action: requestDeleteConfirmation) {
          Image(systemName: "checkmark")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(.violet600)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(selectedNotes.isEmpty)
        .accessibilityLabel("선택한 노트 삭제")
      }
      .sharedBackgroundVisibility(.hidden)
    }
    .destructiveConfirmationAlert(item: $confirmationAlert)
    .toast(item: $toast)
  }

  private var filterChips: some View {
    NoteFilterChipBar(
      filters: viewModel.availableFilters,
      selectedFilter: viewModel.selectedFilter
    ) { filter in
      viewModel.selectedFilter = filter
    }
  }

  /// 필터로 숨겨진 노트가 함께 삭제되지 않도록 현재 보이는 노트 중 선택된 것만 대상으로 합니다.
  private var selectedNotes: [Note] {
    viewModel.filteredNotes.filter { selectedNoteIDs.contains($0.id) }
  }

  private func toggleSelection(for id: Note.ID) {
    if selectedNoteIDs.contains(id) {
      selectedNoteIDs.remove(id)
    } else {
      selectedNoteIDs.insert(id)
    }
  }

  private func requestDeleteConfirmation() {
    let notes = selectedNotes
    guard !notes.isEmpty else {
      return
    }

    confirmationAlert = DestructiveConfirmationAlert(
      title: notes.count > 1
        ? "선택한 연락처 \(notes.count)명의 노트를\n영구적으로 삭제하겠습니까?"
        : "해당 노트를\n영구적으로 삭제하겠습니까?",
      message: notes.count > 1
        ? "선택한 연락처들의 모든 노트와 파일이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다."
        : "연락처 내 모든 노트와 파일이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.",
      acknowledgementText: nil
    ) {
      delete(notes)
    }
  }

  private func delete(_ notes: [Note]) {
    guard onDelete(notes) else {
      toast = Toast(message: "노트를 삭제하지 못했습니다.", style: .failure)
      return
    }

    onDeleted(notes.count)
  }
}

private struct NotesDeletionRow: View {
  let note: Note
  let isSelected: Bool
  let onToggle: () -> Void

  var body: some View {
    Button(action: onToggle) {
      HStack(spacing: 12) {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 28, weight: .medium))
          .foregroundStyle(isSelected ? .gray900 : .gray300)
          .frame(width: 28, height: 28)

        NoteRowView(note: note)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(note.contactName), \(isSelected ? "선택됨" : "선택 안 됨")")
  }
}
