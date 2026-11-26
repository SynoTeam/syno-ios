import Foundation
import Observation
import Testing
@testable import Syno

/// 아카이브 음성 목록 재생 카드의 재생 규칙입니다 (#144).
/// 실제 오디오 대신 테스트 대역 플레이어로 고정합니다.
@MainActor
struct VoiceMemoPlaybackControllerTests {
  private let first = UUID()
  private let second = UUID()
  private let audio = Data([0x01])

  @Test("처음 누르면 그 메모를 재생한다")
  func togglePlaysNewNote() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)

    #expect(controller.isPlaying(first))
    #expect(factory.players.count == 1)
    #expect(factory.players[0].playCount == 1)
  }

  @Test("재생 중 다시 누르면 일시정지하고, 또 누르면 같은 위치에서 이어서 재생한다")
  func toggleSameNotePausesAndResumes() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)
    factory.players[0].currentTime = 5
    controller.toggle(noteID: first, audioData: audio)

    #expect(!controller.isPlaying(first))
    #expect(controller.elapsed(for: first) == 5)

    controller.toggle(noteID: first, audioData: audio)

    #expect(controller.isPlaying(first))
    #expect(factory.players.count == 1, "이어서 재생할 때 플레이어를 새로 만들면 처음부터 재생됩니다")
    #expect(factory.players[0].playCount == 2)
  }

  @Test("다른 메모를 재생하면 앞의 메모는 멈춘다")
  func togglingAnotherNoteStopsPrevious() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)
    controller.toggle(noteID: second, audioData: audio)

    #expect(factory.players[0].stopCount == 1)
    #expect(!controller.isPlaying(first))
    #expect(controller.elapsed(for: first) == 0)
    #expect(controller.isPlaying(second))
  }

  @Test("끝까지 재생하면 처음 상태(정지, 00:00)로 돌아간다")
  func finishingResetsState() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)
    factory.players[0].currentTime = 3
    factory.players[0].finish()

    #expect(!controller.isPlaying(first))
    #expect(controller.elapsed(for: first) == 0)

    // 다시 누르면 처음부터 새로 재생한다.
    controller.toggle(noteID: first, audioData: audio)
    #expect(controller.isPlaying(first))
    #expect(factory.players.count == 2)
  }

  @Test("앞 메모의 늦은 종료 알림이 지금 재생 중인 메모를 멈추지 않는다")
  func staleFinishIsIgnored() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)
    controller.toggle(noteID: second, audioData: audio)
    factory.players[0].finish()

    #expect(controller.isPlaying(second))
  }

  @Test("오디오를 열지 못하면 재생하지 않고 실패를 알린다")
  func playerCreationFailure() {
    let factory = FakePlayerFactory()
    factory.shouldThrow = true
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    let didStart = controller.toggle(noteID: first, audioData: audio)

    #expect(!didStart)
    #expect(!controller.isPlaying(first))
  }

  @Test("재생을 시작하지 못하면(오디오 세션 실패 등) 재생 중으로 표시하지 않는다")
  func playFailure() {
    let factory = FakePlayerFactory()
    factory.playSucceeds = false
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    let didStart = controller.toggle(noteID: first, audioData: audio)

    #expect(!didStart)
    #expect(!controller.isPlaying(first))
  }

  @Test("멈추면 플레이어를 정리하고 처음 상태로 돌아간다(화면을 나가거나 카드를 접을 때)")
  func stopResets() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)
    factory.players[0].currentTime = 2
    controller.stop()

    #expect(factory.players[0].stopCount == 1)
    #expect(!controller.isPlaying(first))
    #expect(controller.elapsed(for: first) == 0)
  }

  @Test("목록에서 사라진 메모를 재생 중이면 멈추고, 아니면 그대로 둔다")
  func stopUnlessVisible() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)
    controller.stop(unlessVisible: [first, second])
    #expect(controller.isPlaying(first))

    controller.stop(unlessVisible: [second])
    #expect(!controller.isPlaying(first))
  }

  @Test("재생 중 위치를 옮기면 그 위치에서 계속 재생한다")
  func seekWhilePlaying() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)
    controller.seek(noteID: first, audioData: audio, to: 7)

    #expect(controller.elapsed(for: first) == 7)
    #expect(controller.isPlaying(first))
    #expect(factory.players.count == 1)
  }

  @Test("재생 전에 위치를 옮기면 멈춘 채로 옮기고, 재생하면 그 위치부터 재생한다")
  func seekBeforePlaying() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.seek(noteID: first, audioData: audio, to: 4)

    #expect(!controller.isPlaying(first))
    #expect(controller.elapsed(for: first) == 4)

    controller.toggle(noteID: first, audioData: audio)
    #expect(controller.isPlaying(first))
    #expect(factory.players.count == 1, "옮긴 위치를 지키려면 같은 플레이어로 재생해야 합니다")
    #expect(controller.elapsed(for: first) == 4)
  }

  @Test("다른 메모의 위치를 옮기면 앞의 재생은 멈춘다")
  func seekAnotherNoteStopsPrevious() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)
    controller.seek(noteID: second, audioData: audio, to: 2)

    #expect(factory.players[0].stopCount == 1)
    #expect(!controller.isPlaying(first))
    #expect(controller.elapsed(for: second) == 2)
  }

  @Test("음수 위치는 처음(0)으로 옮긴다")
  func seekClampsNegative() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.seek(noteID: first, audioData: audio, to: -3)

    #expect(controller.elapsed(for: first) == 0)
  }

  @Test("전화 등으로 오디오가 중단되면 일시정지 상태가 되고, 다시 누르면 같은 위치에서 이어서 재생한다")
  func interruptionPauses() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)
    factory.players[0].currentTime = 6
    factory.players[0].interrupt()

    #expect(!controller.isPlaying(first))
    #expect(controller.elapsed(for: first) == 6)

    controller.toggle(noteID: first, audioData: audio)
    #expect(controller.isPlaying(first))
    #expect(factory.players.count == 1)
    #expect(factory.players[0].playCount == 2)
  }

  @Test("앞 메모의 늦은 중단 알림은 지금 재생 중인 메모에 영향이 없다")
  func staleInterruptionIsIgnored() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)
    controller.toggle(noteID: second, audioData: audio)
    factory.players[0].interrupt()

    #expect(controller.isPlaying(second))
  }

  @Test("일시정지 중에 위치를 옮겨도 화면이 바뀐 위치를 다시 읽는다")
  func seekWhilePausedNotifiesObservers() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)
    controller.seek(noteID: first, audioData: audio, to: 10)

    var didChange = false
    withObservationTracking {
      _ = controller.elapsed(for: first)
    } onChange: {
      didChange = true
    }
    controller.seek(noteID: first, audioData: audio, to: 15)

    #expect(didChange, "위치를 옮겨도 화면이 갱신되지 않으면 VoiceOver 조절이 예전 위치에서 계산됩니다")
    #expect(controller.elapsed(for: first) == 15)
  }

  @Test("재생하지 않는 메모의 경과 시간은 0이다")
  func elapsedForOtherNote() {
    let factory = FakePlayerFactory()
    let controller = VoiceMemoPlaybackController(makePlayer: factory.make)

    controller.toggle(noteID: first, audioData: audio)
    factory.players[0].currentTime = 4

    #expect(controller.elapsed(for: second) == 0)
  }
}

@MainActor
private final class FakePlayerFactory {
  var players: [FakeAudioPlayer] = []
  var shouldThrow = false
  var playSucceeds = true

  func make(_ data: Data) throws -> any VoiceMemoAudioPlaying {
    struct OpenFailed: Error {}
    if shouldThrow { throw OpenFailed() }
    let player = FakeAudioPlayer(playSucceeds: playSucceeds)
    players.append(player)
    return player
  }
}

@MainActor
private final class FakeAudioPlayer: VoiceMemoAudioPlaying {
  var currentTime: TimeInterval = 0
  var onFinish: (() -> Void)?
  var onInterruption: (() -> Void)?
  private(set) var playCount = 0
  private(set) var stopCount = 0
  private let playSucceeds: Bool

  init(playSucceeds: Bool) {
    self.playSucceeds = playSucceeds
  }

  func play() -> Bool {
    playCount += 1
    return playSucceeds
  }

  func pause() {}

  func seek(to time: TimeInterval) {
    currentTime = time
  }

  func stop() {
    stopCount += 1
    currentTime = 0
  }

  func interrupt() {
    onInterruption?()
  }

  func finish() {
    currentTime = 0
    onFinish?()
  }
}
