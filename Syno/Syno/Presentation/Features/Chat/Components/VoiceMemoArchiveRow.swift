import SwiftUI

/// 아카이브 음성 목록의 접힌 행입니다. 제목, 날짜, 길이를 한 줄씩 보여 줍니다 (#144).
struct VoiceMemoArchiveRow: View {
  let note: Note

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(note.content)
        .typeStyle(.bodyEmphasized)
        .foregroundStyle(.gray950)
        .lineLimit(1)
        .truncationMode(.tail)

      HStack(spacing: 8) {
        Text(ArchiveFormatters.dayText(for: note.createdAt))
        Spacer(minLength: 8)
        Text(ArchiveFormatters.playbackTimeText(note.voiceMemoDuration))
          .monospacedDigit()
      }
      .typeStyle(.subheadline)
      .foregroundStyle(.gray500)
    }
    .padding(.vertical, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}

/// 음성 행을 눌렀을 때 펼쳐지는 재생 카드입니다. 진행 막대, 시간, 변환 텍스트(모달)·재생·파일에 저장 버튼이 있습니다 (#144).
struct VoiceMemoPlayerCard: View {
  let note: Note
  let isPlaying: Bool
  /// 재생 위치는 플레이어에서 바로 읽습니다. 재생 중에만 주기적으로 다시 읽어 막대를 움직입니다.
  let elapsed: () -> TimeInterval
  let onCollapse: () -> Void
  let onTogglePlayback: () -> Void
  /// 진행 막대를 누르거나 끈 위치(초)로 옮깁니다.
  let onSeek: (TimeInterval) -> Void
  /// 이번 실행 중 파일 앱에 저장했으면 저장 버튼을 막습니다.
  let isSaved: Bool
  /// 변환 텍스트 모달을 엽니다.
  let onShowTranscript: () -> Void
  /// 파일 앱으로 저장합니다.
  let onDownload: () -> Void

  /// 막대를 끄는 동안의 위치(0...1)입니다. 손을 떼면 그 위치로 옮기고 지웁니다.
  @State private var dragFraction: Double?

  private var duration: TimeInterval { note.voiceMemoDuration ?? 0 }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 제목 부분을 다시 누르면 접는다.
      Button(action: onCollapse) {
        VStack(alignment: .leading, spacing: 4) {
          Text(note.content)
            .typeStyle(.bodyEmphasized)
            .foregroundStyle(.gray950)
            .lineLimit(1)
            .truncationMode(.tail)
          Text(ArchiveFormatters.dayText(for: note.createdAt))
            .typeStyle(.subheadline)
            .foregroundStyle(.gray500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(note.content) 접기")

      // 재생 중에는 화면 주사율마다 다시 그려 막대가 끊기지 않고 부드럽게 움직인다.
      TimelineView(.animation(paused: !isPlaying)) { _ in
        progress(elapsed: dragFraction.map { $0 * duration } ?? elapsed())
      }
      .padding(.horizontal, 10)
      .padding(.top, 24)

      controls
        .padding(.horizontal, 4)
        .padding(.top, 12)
    }
    .padding(16)
    .background(.gray50, in: RoundedRectangle(cornerRadius: 20))
  }

  private func progress(elapsed: TimeInterval) -> some View {
    VStack(spacing: 8) {
      GeometryReader { proxy in
        let fraction = ArchiveFormatters.playbackProgress(elapsed: elapsed, duration: duration)
        // 그라데이션은 막대 전체 폭에 고정하고 채운 만큼만 보여 준다. 채운 폭에 맞춰 그라데이션을 늘리면
        // 재생하는 동안 색이 계속 움직여 흔들려 보인다. 모서리는 바탕 캡슐로 잘라 짧을 때도 모양이 일정하다.
        ZStack(alignment: .leading) {
          Rectangle().fill(.gray100)
          LinearGradient(colors: [.violet600, .violet300], startPoint: .leading, endPoint: .trailing)
            .mask(alignment: .leading) {
              Rectangle().frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: 4)
        .clipShape(Capsule())
        .frame(maxHeight: .infinity)
        .transaction { $0.animation = nil }
        // 막대는 4pt로 얇아서, 위아래로 넓힌 영역 전체에서 누르거나 끌 수 있게 한다.
        .contentShape(Rectangle())
        .gesture(seekGesture(width: proxy.size.width))
      }
      .frame(height: 24)
      .padding(.vertical, -10)
      .accessibilityElement()
      .accessibilityLabel("재생 위치")
      .accessibilityValue(ArchiveFormatters.playbackTimeText(elapsed))
      .accessibilityAdjustableAction { direction in
        // VoiceOver에서는 위아래 쓸기로 5초씩 옮긴다.
        let step: TimeInterval = direction == .increment ? 5 : -5
        onSeek(min(max(elapsed + step, 0), duration))
      }

      HStack {
        Text(ArchiveFormatters.playbackTimeText(elapsed))
          .accessibilityIdentifier("voice.elapsed")
        Spacer()
        Text(ArchiveFormatters.playbackTimeText(duration))
      }
      .typeStyle(.caption1)
      .foregroundStyle(.gray500)
      .monospacedDigit()
    }
  }

  private func seekGesture(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        guard width > 0, duration > 0 else { return }
        dragFraction = min(max(value.location.x / width, 0), 1)
      }
      .onEnded { _ in
        guard let dragFraction else { return }
        onSeek(dragFraction * duration)
        self.dragFraction = nil
      }
  }

  private var controls: some View {
    HStack {
      Button(action: onShowTranscript) {
        icon(.message, color: .gray600)
      }
      .buttonStyle(CirclePressButtonStyle())
      .accessibilityLabel("변환 텍스트 보기")

      Spacer()

      Button(action: onTogglePlayback) {
        Image(isPlaying ? .pause : .play)
          .resizable()
          .renderingMode(.template)
          .foregroundStyle(.gray800)
          .frame(width: 24, height: 24)
          .frame(width: 56, height: 56)
          // 시안: 멈춤 상태는 gray100 원, 재생 중은 흰 원
          .background(isPlaying ? Color.white : Color.gray100, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isPlaying ? "일시정지" : "재생")

      Spacer()

      saveButton
    }
  }

  private var saveButton: some View {
    Button(action: onDownload) {
      icon(.download, color: isSaved ? .gray300 : .gray600)
    }
    .buttonStyle(CirclePressButtonStyle())
    .disabled(isSaved)
    .accessibilityLabel(isSaved ? "파일에 저장함" : "파일에 저장")
  }

  private func icon(_ resource: ImageResource, color: Color) -> some View {
    Image(resource)
      .resizable()
      .renderingMode(.template)
      .foregroundStyle(color)
      .frame(width: 24, height: 24)
      .frame(width: 36, height: 36)
  }
}
