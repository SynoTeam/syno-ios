import AVFoundation

/// `AVAudioPlayer`로 음성 메모를 재생합니다 (#144).
@MainActor
final class AVVoiceMemoAudioPlayer: NSObject, VoiceMemoAudioPlaying {
  var onFinish: (() -> Void)?
  var onInterruption: (() -> Void)?
  private let player: AVAudioPlayer

  init(data: Data) throws {
    player = try AVAudioPlayer(data: data)
    super.init()
    player.delegate = self
    player.prepareToPlay()
    // 전화 등으로 재생이 중단되면 시스템이 플레이어를 멈추지만 종료 알림은 오지 않으므로 따로 받는다.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance()
    )
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
    guard player.play() else {
      Self.deactivateSession()
      return false
    }
    return true
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
    Self.deactivateSession()
  }

  /// 재생이 끝나면 오디오 세션을 돌려줘, 우리 재생 때문에 멈춘 다른 앱(음악 등)이 다시 재생할 수 있게 한다.
  private nonisolated static func deactivateSession() {
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  @objc private nonisolated func handleInterruption(_ notification: Notification) {
    guard
      let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
      AVAudioSession.InterruptionType(rawValue: rawType) == .began
    else { return }
    Task { @MainActor in
      self.onInterruption?()
    }
  }
}

extension AVVoiceMemoAudioPlayer: AVAudioPlayerDelegate {
  nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    Self.deactivateSession()
    Task { @MainActor in
      self.onFinish?()
    }
  }
}
