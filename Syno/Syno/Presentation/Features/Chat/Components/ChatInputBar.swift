import SwiftUI

/// 채팅 하단의 입력 영역입니다. `+` 첨부 메뉴, 입력 필드, 전송 버튼으로 구성합니다.
/// 권한 확인이나 전송 같은 동작은 하지 않고, 사용자의 선택을 콜백으로 알립니다.
struct ChatInputBar: View {
  let text: Binding<String>
  var isFocused: FocusState<Bool>.Binding
  let canSend: Bool
  let recorder: VoiceRecorder
  let onCamera: () -> Void
  let onAlbum: () -> Void
  let onFile: () -> Void
  let onVoiceMemo: () -> Void
  /// 텍스트 전송, 녹음 시작, 녹음 정지·전송 중 지금 상태에 맞는 동작은 호출하는 쪽에서 결정합니다.
  let onSendTapped: () -> Void

  var body: some View {
    HStack(alignment: .bottom, spacing: 10) {
      ChatAttachmentMenu(
        onCamera: onCamera,
        onAlbum: onAlbum,
        onFile: onFile,
        onVoiceMemo: onVoiceMemo
      )

      inputField
    }
    .padding(.horizontal, 14)
    .padding(.top, 10)
    .padding(.bottom, 10)
    .background(Color.gray50)
  }

  /// 내용에 따라 세로로 늘어나는 입력 필드입니다. 전송 버튼은 필드 안쪽 오른쪽 아래에 고정됩니다.
  /// 최대 6줄까지 늘어나고 그 이후에는 필드 안에서 스크롤됩니다.
  private var inputField: some View {
    HStack(alignment: .bottom, spacing: 8) {
      if recorder.isRecording {
        ChatRecordingIndicator(recorder: recorder)
      } else {
        TextField("메모 입력", text: text, axis: .vertical)
          .typeStyle(.body)
          .lineLimit(1...6)
          .focused(isFocused)
          .padding(.leading, 16)
          .padding(.vertical, 12)
      }

      sendButton
    }
    .padding(.trailing, 2)
    .padding(.bottom, 2)
    .frame(minHeight: 44)
    .background(.gray100)
    .clipShape(RoundedRectangle(cornerRadius: 22))
  }

  private var sendButton: some View {
    Button(action: onSendTapped) {
      sendButtonIcon
        .foregroundStyle(.white)
        .frame(width: 40, height: 40)
        // 텍스트 전송 가능할 때만 보라색이고, 음성 녹음 대기와 녹음 중에는 짙은 회색을 쓴다.
        .background((canSend && !recorder.isRecording) ? .violet600 : .gray700)
        .clipShape(Circle())
    }
    .accessibilityLabel(recorder.isRecording ? "녹음 중지" : "메모 보내기 또는 음성 녹음")
  }

  @ViewBuilder
  private var sendButtonIcon: some View {
    if recorder.isRecording {
      Image(.stop)
        .resizable()
        .renderingMode(.template)
        .frame(width: 20, height: 20)
    } else if canSend {
      Image(.arrowUp)
        .resizable()
        .renderingMode(.template)
        .frame(width: 20, height: 20)
    } else {
      Image(.sliders)
        .resizable()
        .renderingMode(.template)
        .frame(width: 20, height: 20)
    }
  }
}

/// 입력창 왼쪽의 `+` 버튼과 첨부 메뉴입니다. 항목 순서는 Figma 기준으로 고정합니다.
struct ChatAttachmentMenu: View {
  let onCamera: () -> Void
  let onAlbum: () -> Void
  let onFile: () -> Void
  let onVoiceMemo: () -> Void

  var body: some View {
    Menu {
      Button(action: onCamera) {
        menuLabel("카메라", icon: .camera)
      }

      Button(action: onAlbum) {
        menuLabel("앨범", icon: .image)
      }

      Button(action: onFile) {
        menuLabel("파일", icon: .document)
      }

      Button(action: onVoiceMemo) {
        menuLabel("음성 메모", icon: .sliders)
      }
    } label: {
      Image(.plus)
        .resizable()
        .renderingMode(.template)
        .foregroundStyle(.gray700)
        .frame(width: 22, height: 22)
        .frame(width: 44, height: 44)
        .background(.gray100)
        .clipShape(Circle())
    }
    // 메뉴가 버튼 위로 열릴 때 iOS가 순서를 뒤집지 않고 선언한 순서대로 위에서 아래로 보여준다.
    .menuOrder(.fixed)
    .accessibilityLabel("메모 추가")
  }

  /// + 메뉴 항목의 라벨입니다. 프로젝트 아이콘 에셋을 템플릿으로 그려 시스템 아이콘처럼 보이게 합니다.
  private func menuLabel(_ title: String, icon: ImageResource) -> some View {
    Label {
      Text(title)
    } icon: {
      Image(icon)
        .renderingMode(.template)
    }
  }
}

/// 녹음 중 입력 필드 안에 보이는 파형과 경과 시간입니다.
struct ChatRecordingIndicator: View {
  let recorder: VoiceRecorder

  var body: some View {
    // Figma처럼 파형과 시간을 오른쪽(정지 버튼 쪽)으로 모아 보여준다.
    HStack(spacing: 12) {
      Spacer(minLength: 0)

      HStack(spacing: 1.5) {
        ForEach(recorder.levels.indices, id: \.self) { index in
          Capsule()
            .fill(Color.violet400)
            .frame(width: 2, height: max(6, recorder.levels[index] * 30))
            .animation(.easeInOut(duration: 0.15), value: recorder.levels[index])
        }
      }
      .clipped()
      .animation(.easeInOut(duration: 0.1), value: recorder.levels.count)

      Text(String(format: "%d:%02d", Int(recorder.duration) / 60, Int(recorder.duration) % 60))
        .typeStyle(.subheadline)
        .foregroundStyle(.gray400)
        .monospacedDigit()
    }
    .padding(.leading, 16)
    .frame(maxWidth: .infinity)
    .frame(height: 40)
  }
}
