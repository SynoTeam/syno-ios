import Foundation
import Observation

/// 음성 메모 하나를 재생하는 플레이어입니다. 실제 구현은 `AVVoiceMemoAudioPlayer`이고, 테스트에서는 대역으로 바꿉니다.
@MainActor
protocol VoiceMemoAudioPlaying: AnyObject {
  /// 지금까지 재생한 위치(초)입니다. 일시정지해도 유지됩니다.
  var currentTime: TimeInterval { get }
  /// 끝까지 재생했을 때 불립니다.
  var onFinish: (() -> Void)? { get set }
  /// 재생을 시작합니다. 오디오 세션을 열지 못하는 등 시작하지 못하면 false입니다.
  func play() -> Bool
  func pause()
  func stop()
  /// 재생 위치를 옮깁니다. 재생 중이면 옮긴 위치에서 계속 재생합니다.
  func seek(to time: TimeInterval)
}

/// 아카이브 음성 목록에서 한 번에 한 메모만 재생하도록 관리합니다 (#144).
/// 화면은 메모 ID로 재생 여부와 경과 시간만 읽습니다.
@MainActor
@Observable
final class VoiceMemoPlaybackController {
  private(set) var playingNoteID: UUID?
  private(set) var isPlaying = false

  @ObservationIgnored private var currentNoteID: UUID?
  @ObservationIgnored private var player: (any VoiceMemoAudioPlaying)?
  @ObservationIgnored private let makePlayer: @MainActor (Data) throws -> any VoiceMemoAudioPlaying

  init(makePlayer: @escaping @MainActor (Data) throws -> any VoiceMemoAudioPlaying) {
    self.makePlayer = makePlayer
  }

  /// 앱에서는 `AVAudioPlayer`로 재생합니다.
  /// 아카이브 음성 탭 화면만 쓰는 재생 상태라 화면이 `@State`로 직접 만듭니다(생성자 주입 규칙의 예외).
  /// 저장·데이터 접근은 하지 않고, 테스트는 `init(makePlayer:)`로 대역 플레이어를 넣습니다.
  convenience init() {
    self.init(makePlayer: { try AVVoiceMemoAudioPlayer(data: $0) })
  }

  /// 같은 메모면 일시정지/이어서 재생하고, 다른 메모면 앞의 재생을 멈추고 처음부터 재생합니다.
  /// 재생을 시작하지 못하면 false입니다.
  @discardableResult
  func toggle(noteID: UUID, audioData: Data) -> Bool {
    if currentNoteID == noteID, let player {
      if isPlaying {
        player.pause()
        isPlaying = false
        return true
      }
      isPlaying = player.play()
      return isPlaying
    }

    guard let newPlayer = switchPlayer(to: noteID, audioData: audioData) else { return false }
    guard newPlayer.play() else {
      reset()
      return false
    }
    isPlaying = true
    return true
  }

  /// 진행 막대를 누르거나 끌어 위치를 옮깁니다. 재생 중이면 그 위치에서 계속 재생하고,
  /// 재생 전이면 멈춘 채로 옮겨 두었다가 재생 버튼을 누르면 그 위치부터 재생합니다.
  func seek(noteID: UUID, audioData: Data, to time: TimeInterval) {
    let target: any VoiceMemoAudioPlaying
    if currentNoteID == noteID, let player {
      target = player
    } else {
      guard let newPlayer = switchPlayer(to: noteID, audioData: audioData) else { return }
      target = newPlayer
    }
    target.seek(to: max(time, 0))
  }

  /// 앞의 재생을 멈추고 이 메모의 플레이어를 멈춘 상태로 준비합니다.
  private func switchPlayer(to noteID: UUID, audioData: Data) -> (any VoiceMemoAudioPlaying)? {
    stop()
    let newPlayer: any VoiceMemoAudioPlaying
    do {
      newPlayer = try makePlayer(audioData)
    } catch {
      return nil
    }
    newPlayer.onFinish = { [weak self, weak newPlayer] in
      // 앞에서 멈춘 플레이어의 늦은 알림은 무시한다.
      guard let self, let newPlayer, self.player === newPlayer else { return }
      self.reset()
    }
    player = newPlayer
    currentNoteID = noteID
    playingNoteID = noteID
    return newPlayer
  }

  func isPlaying(_ noteID: UUID) -> Bool {
    isPlaying && playingNoteID == noteID
  }

  /// 경과 시간은 플레이어에서 바로 읽습니다. 화면은 재생 중에만 주기적으로 다시 그려 막대를 움직입니다.
  func elapsed(for noteID: UUID) -> TimeInterval {
    guard currentNoteID == noteID, let player else { return 0 }
    return player.currentTime
  }

  /// 재생을 멈추고 처음 상태로 돌립니다. 카드를 접거나 화면을 나갈 때 씁니다.
  func stop() {
    player?.stop()
    reset()
  }

  /// 재생 중인 메모가 삭제·검색으로 목록에서 사라졌으면 멈춥니다.
  func stop(unlessVisible ids: Set<UUID>) {
    guard let currentNoteID, !ids.contains(currentNoteID) else { return }
    stop()
  }

  private func reset() {
    player?.onFinish = nil
    player = nil
    currentNoteID = nil
    playingNoteID = nil
    isPlaying = false
  }
}
