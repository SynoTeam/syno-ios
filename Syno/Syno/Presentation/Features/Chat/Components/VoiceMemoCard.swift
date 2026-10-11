import AVFoundation
import SwiftUI

struct VoiceMemoCard: View {
  let note: Note
  @State private var player: AVAudioPlayer?
  @State private var isPlaying = false
  @State private var playerDelegate = PlayerDelegate()

  /// 막대 설정입니다. 폭 3, 간격 2로 139pt 안에 28개가 들어갑니다.
  private static let barCount = 28
  private static let barWidth: CGFloat = 3
  private static let barSpacing: CGFloat = 2
  private static let minBarHeight: CGFloat = 4
  private static let maxBarHeight: CGFloat = 24

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 0) {
        playButton

        Spacer(minLength: 12)

        waveform
      }

      HStack(spacing: 8) {
        Text(note.content)
          .typeStyle(.footnoteEmphasized)
          .foregroundStyle(.white)
          .lineLimit(1)
          .truncationMode(.tail)
        Spacer(minLength: 8)
        Text(durationText)
          .typeStyle(.caption1)
          .foregroundStyle(.gray300)
          .fixedSize()
      }
      .padding(.horizontal, 4)
    }
    .padding(.leading, 8)
    .padding(.trailing, 12)
    .padding(.top, 8)
    .padding(.bottom, 12)
    .frame(width: 240, height: 83, alignment: .topLeading)
    .background(.black.opacity(0.2))
    .background(Color.gray800)
    .cornerRadius(20)
  }

  private var playButton: some View {
    Button(action: togglePlayback) {
      Image(isPlaying ? .pause : .play)
        .resizable()
        .renderingMode(.template)
        .foregroundStyle(.gray50)
        .frame(width: 16, height: 16)
        .frame(width: 32, height: 32)
        .background(.gray700)
        .clipShape(Circle())
    }
  }

  private var waveform: some View {
    let samples = displaySamples
    return HStack(spacing: Self.barSpacing) {
      ForEach(samples.indices, id: \.self) { index in
        Capsule()
          .fill(Color.violet300)
          .frame(width: Self.barWidth, height: barHeight(for: samples[index]))
      }
    }
    .frame(height: Self.maxBarHeight)
  }

  /// 저장된 파형을 화면에 그릴 막대 수로 맞춥니다. 예전에 저장된 20개짜리 파형도 같은 모양으로 보이게 보간합니다.
  private var displaySamples: [Float] {
    guard let waveform = note.voiceMemoWaveform, !waveform.isEmpty else {
      return (0..<Self.barCount).map { 0.35 + 0.25 * abs(sin(Float($0) * 0.7)) }
    }
    guard waveform.count != Self.barCount else {
      return waveform
    }

    return (0..<Self.barCount).map { index in
      let position = Float(index) / Float(Self.barCount - 1) * Float(waveform.count - 1)
      let lower = Int(position)
      let upper = min(lower + 1, waveform.count - 1)
      let fraction = position - Float(lower)
      return waveform[lower] * (1 - fraction) + waveform[upper] * fraction
    }
  }

  private func barHeight(for sample: Float) -> CGFloat {
    Self.minBarHeight + CGFloat(max(0, min(1, sample))) * (Self.maxBarHeight - Self.minBarHeight)
  }

  private var durationText: String { String(format: "%02d:%02d", Int(note.voiceMemoDuration ?? 0) / 60, Int(note.voiceMemoDuration ?? 0) % 60) }

  private func togglePlayback() {
    if let player {
      if player.isPlaying {
        player.pause()
        isPlaying = false
      } else {
        do {
          try activateSession()
          player.play()
          isPlaying = true
        } catch { isPlaying = false }
      }
      return
    }

    guard let data = note.voiceMemoData else { return }
    do {
      try activateSession()
      let newPlayer = try AVAudioPlayer(data: data)
      playerDelegate.didFinishPlaying = { Task { @MainActor in isPlaying = false; player = nil } }
      newPlayer.delegate = playerDelegate
      newPlayer.play()
      player = newPlayer
      isPlaying = true
    } catch { isPlaying = false }
  }

  private func activateSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .default)
    try session.setActive(true)
  }
}

private final class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
  var didFinishPlaying: (() -> Void)?

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    didFinishPlaying?()
  }
}
