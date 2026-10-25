import SwiftUI

/// 생일, 기념일처럼 선택 사항인 날짜를 시트의 휠 선택기로 고르는 행입니다.
struct AddContactDateRow: View {
  /// 행 왼쪽에 표시할 제목입니다.
  let title: String

  /// 부모 폼 상태와 연결된 날짜입니다. 값이 없으면 선택하지 않은 상태입니다.
  @Binding var date: Date?

  @State private var isShowingPicker = false

  var body: some View {
    HStack(spacing: 12) {
      Text(title)
        .typeStyle(.body)
        .foregroundStyle(.gray950)

      Spacer()

      if date != nil {
        Button {
          date = nil
        } label: {
          Image(.xCircle)
            .resizable()
            .renderingMode(.template)
            .frame(width: 20, height: 20)
            .foregroundStyle(.gray400)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) 지우기")
      }

      Button {
        isShowingPicker = true
      } label: {
        HStack(spacing: 4) {
          if date != nil {
            Text(dateText)
              .typeStyle(.bodyEmphasized)
              .foregroundStyle(.gray900)
          }

          Image(.chevronRight)
            .resizable()
            .renderingMode(.template)
            .frame(width: 20, height: 20)
            .foregroundStyle(.gray500)
        }
        // 날짜가 비어 있으면 화살표뿐이라 누르기 어려워서 최소 터치 영역을 44pt로 둔다.
        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(title) 선택")
    }
    .frame(height: 54)
    .sheet(isPresented: $isShowingPicker) {
      AddContactDatePickerSheet(title: title, date: $date)
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
    }
  }

  private var dateText: String {
    guard let date else {
      return ""
    }
    return date.formatted(.dateTime.year().month().day())
  }
}

/// 휠 선택기를 보여주고 "완료"를 눌렀을 때만 선택한 날짜를 반영하는 시트입니다.
private struct AddContactDatePickerSheet: View {
  @Environment(\.dismiss) private var dismiss

  let title: String
  @Binding var date: Date?

  @State private var draft: Date

  init(title: String, date: Binding<Date?>) {
    self.title = title
    _date = date
    _draft = State(initialValue: date.wrappedValue ?? Date())
  }

  var body: some View {
    NavigationStack {
      DatePicker(
        title,
        selection: $draft,
        displayedComponents: .date
      )
      .datePickerStyle(.wheel)
      .labelsHidden()
      .tint(.violet500)
      .padding(.horizontal, 16)
      .frame(maxHeight: .infinity, alignment: .top)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .close) {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("완료") {
            date = draft
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  AddContactDateRow(title: "생일", date: .constant(nil))
    .padding(.horizontal, 22)
    .background(.white)
}
