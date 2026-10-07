import SwiftUI

/// 생일, 기념일처럼 선택 사항인 날짜를 시트의 그래픽 달력으로 고르는 행입니다.
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

      Button {
        isShowingPicker = true
      } label: {
        Text(dateText)
          .typeStyle(.subheadlineEmphasized)
          .foregroundStyle(date == nil ? .gray400 : .gray700)
          .padding(.horizontal, 12)
          .frame(height: 36)
          .background(.gray100)
          .clipShape(Capsule())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(title) 선택")

      if date != nil {
        Button {
          date = nil
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.gray400)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) 지우기")
      }
    }
    .frame(height: 54)
    .sheet(isPresented: $isShowingPicker) {
      AddContactDatePickerSheet(title: title, date: $date)
        .presentationDetents([.height(480)])
        .presentationDragIndicator(.visible)
    }
  }

  private var dateText: String {
    guard let date else {
      return "선택하기"
    }
    return date.formatted(.dateTime.year().month().day())
  }
}

/// 그래픽 달력을 보여주고 "완료"를 눌렀을 때만 선택한 날짜를 반영하는 시트입니다.
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
      .datePickerStyle(.graphical)
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
