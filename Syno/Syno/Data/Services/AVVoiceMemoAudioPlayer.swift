import AVFoundation

/// `AVAudioPlayer`로 음성 메모를 재생합니다 (#144).
@MainActor
final class AVVoiceMemoAudioPlayer: NSObject, VoiceMemoAudioPlaying {
  var onFinish: (() -> Void)?
  private let player: AVAudioPlayer

  init(data: Data) throws {
    player = try AVAudioPlayer(data: data)
    super.init()
    player.delegate = self
    player.prepareToPlay()
  }

  var currentTime: TimeInterval { player.currentTime }

  func play() -> Bool {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)
    } catch {
      return false
    }
    return player.play()
  }

  func pause() {
    player.pause()
  }

  func seek(to time: TimeInterval) {
    player.currentTime = min(max(time, 0), player.duration)
  }

  func stop() {
    player.stop()
    player.currentTime = 0
  }
}

extension AVVoiceMemoAudioPlayer: AVAudioPlayerDelegate {
  nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    Task { @MainActor in
      self.onFinish?()
    }
  }
}
