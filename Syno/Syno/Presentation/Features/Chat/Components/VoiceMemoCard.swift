import AVFoundation
import SwiftUI

struct VoiceMemoCard: View {
  let note: Note
  @State private var player: AVAudioPlayer?
  @State private var isPlaying = false
  @State private var playerDelegate = PlayerDelegate()

  var body: some View {
    HStack(spacing: 12) {
      Button(action: togglePlayback) {
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
          .foregroundStyle(.gray50)
          .frame(width: 36, height: 36)
          .background(.gray700)
          .clipShape(Circle())
      }
      VStack(alignment: .leading, spacing: 13) {
        HStack(spacing: 3) {
          ForEach(waveformSamples.indices, id: \.self) { index in
            Capsule()
              .fill(Color.violet300)
              .frame(width: 3, height: barHeight(for: waveformSamples[index]))
          }
        }
        .frame(maxWidth: 139, alignment: .leading)
        .clipped()
        HStack(spacing: 8) {
          Text(note.content).typeStyle(.footnoteEmphasized).foregroundStyle(.white).lineLimit(1)
          Spacer(minLength: 8)
          Text(durationText).typeStyle(.caption1).foregroundStyle(.gray300)
            .fixedSize()
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.leading, 8)
    .padding(.trailing, 12)
    .padding(.top, 8)
    .padding(.bottom, 12)
    .frame(width: 240, alignment: .topLeading)
    .background(.black.opacity(0.2))
    .background(Color(red: 0.13, green: 0.16, blue: 0.22))
    .cornerRadius(20)
  }

  private var waveformSamples: [Float] {
    guard let waveform = note.voiceMemoWaveform, !waveform.isEmpty else {
      return (0..<18).map { Float(0.3 + Double($0 % 5) * 0.1) }
    }
    return waveform
  }

  private func barHeight(for sample: Float) -> CGFloat {
    max(20, CGFloat(sample) * 28)
  }

  private var durationText: String { String(format: "%d:%02d", Int(note.voiceMemoDuration ?? 0) / 60, Int(note.voiceMemoDuration ?? 0) % 60) }

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
