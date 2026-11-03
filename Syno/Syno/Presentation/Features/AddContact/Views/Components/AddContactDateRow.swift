import SwiftUI

/// 생일, 기념일처럼 선택 사항인 날짜를 시트의 휠 선택기로 고르는 행입니다.
///
/// 행 전체가 눌리고, 누르는 동안 카드 가장자리까지 배경이 바뀝니다.
struct AddContactDateRow: View {
  /// 행 왼쪽에 표시할 제목입니다.
  let title: String

  /// 부모 폼 상태와 연결된 날짜입니다. 값이 없으면 선택하지 않은 상태입니다.
  @Binding var date: Date?

  /// 행을 담은 카드의 좌우 안쪽 여백입니다. 눌림 배경과 터치 영역을 이 여백까지 넓힙니다.
  var cardInset: CGFloat = 22

  @State private var isShowingPicker = false
  @State private var isPressed = false

  var body: some View {
    HStack(spacing: 0) {
      Button {
        isShowingPicker = true
      } label: {
        Text(title)
          .typeStyle(.body)
          .foregroundStyle(.gray950)
          .padding(.leading, cardInset)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
          .contentShape(Rectangle())
      }
      .buttonStyle(DateRowPressStyle(isPressed: $isPressed))
      // 오른쪽 버튼과 동작이 같아서 보이스오버에는 하나만 읽히게 한다.
      .accessibilityHidden(true)

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
        .padding(.trailing, 4)
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
        .padding(.trailing, cardInset)
        // 날짜가 비어 있으면 화살표뿐이라 누르기 어려워서 최소 터치 영역을 44pt로 둔다.
        .frame(minWidth: 44 + cardInset, maxHeight: .infinity, alignment: .trailing)
        .contentShape(Rectangle())
      }
      .buttonStyle(DateRowPressStyle(isPressed: $isPressed))
      .accessibilityLabel("\(title) 선택")
    }
    .frame(height: 54)
    .background {
      Color.gray50
        .opacity(isPressed ? 1 : 0)
        .animation(.easeOut(duration: 0.12), value: isPressed)
    }
    // 부모 카드가 좌우에 둔 안쪽 여백까지 행이 채우도록 되돌린다. 카드의 둥근 모서리가 넘치는 부분을 잘라낸다.
    .padding(.horizontal, -cardInset)
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
    return date.formatted(.dateTime.year().month().day().locale(AddContactDateRow.locale))
  }

  /// 앱 문구가 한국어로 고정이라 기기 언어와 관계없이 한국어 날짜 표기를 씁니다.
  /// 프로젝트가 영어만 지원 언어로 등록되어 있어 지정하지 않으면 피커가 영어로 표시됩니다.
  fileprivate static let locale = Locale(identifier: "ko_KR")
}

/// 왼쪽 제목과 오른쪽 선택 영역이 한 행처럼 눌린 상태를 공유하게 하는 버튼 스타일입니다.
private struct DateRowPressStyle: ButtonStyle {
  @Binding var isPressed: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .onChange(of: configuration.isPressed) { _, pressed in
        isPressed = pressed
      }
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
      .environment(\.locale, AddContactDateRow.locale)
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
