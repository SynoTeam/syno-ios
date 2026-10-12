import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class VoiceRecorder {
  private(set) var isRecording = false
  private(set) var duration: TimeInterval = 0
  private(set) var levels: [CGFloat] = []
  private var recorder: AVAudioRecorder?
  private var timer: Timer?
  private var startedAt: Date?

  /// 말풍선에 저장하는 파형의 구간 수입니다. 음성 메모 카드의 막대 수와 같습니다.
  nonisolated static let waveformBucketCount = 28

  enum StartResult {
    case started
    /// 이전에 마이크 권한을 거부한 상태입니다. 시스템 팝업은 다시 뜨지 않으므로 설정 이동을 안내해야 합니다.
    case permissionDenied
    /// 이번에 뜬 시스템 팝업에서 방금 거절한 경우입니다. 추가 안내는 필요하지 않습니다.
    case declinedInPrompt
    case failed
  }

  func start() async -> StartResult {
    if AVAudioApplication.shared.recordPermission == .denied { return .permissionDenied }
    let granted = await AVAudioApplication.requestRecordPermission()
    guard granted else { return .declinedInPrompt }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
    let settings: [String: Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44_100, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
      try audioSession.setActive(true)
      let recorder = try AVAudioRecorder(url: url, settings: settings)
      recorder.isMeteringEnabled = true
      recorder.record()
      self.recorder = recorder
      startedAt = Date()
      duration = 0
      levels = []
      isRecording = true
      timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
        Task { @MainActor in self?.sampleLevel() }
      }
      return .started
    } catch { return .failed }
  }

  func stop() -> (data: Data, duration: TimeInterval, waveform: [Float])? {
    guard let recorder else { return nil }
    let url = recorder.url
    recorder.stop()
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    timer?.invalidate(); timer = nil
    isRecording = false
    let waveform = Self.waveform(fromAudioFileAt: url, bucketCount: Self.waveformBucketCount)
    let result = (try? Data(contentsOf: url)).map { ($0, duration, waveform) }
    try? FileManager.default.removeItem(at: url)
    self.recorder = nil
    return result
  }

  /// 실시간 미터링(averagePower)은 입력창 파형 애니메이션 같은 라이브 표시용으로만 씁니다.
  /// AAC 인코더는 미터링 값을 매 폴링마다 갱신하지 않고 인코더 블록 단위로 드문드문 갱신하기 때문에,
  /// 저장용 파형은 이 값 대신 녹음이 끝난 뒤 실제 오디오 파일을 직접 읽어 계산합니다.
  private static let silenceFloorDb: Float = -50
  /// 보통 말소리는 -10dB 근처가 가장 큰 편이라, 0dB가 아니라 이 값을 최대로 보고 환산해야 파형이 충분히 커집니다.
  private static let loudCeilingDb: Float = -12

  private func sampleLevel() {
    guard let recorder, let startedAt else { return }
    recorder.updateMeters()
    duration = Date().timeIntervalSince(startedAt)
    let power = max(Self.silenceFloorDb, recorder.averagePower(forChannel: 0))
    let range = Self.loudCeilingDb - Self.silenceFloorDb
    let normalized = max(0.08, min(1, (power - Self.silenceFloorDb) / range))
    levels.append(CGFloat(normalized))
    if levels.count > 50 { levels.removeFirst() }
  }

  /// 녹음된 오디오 파일을 직접 읽어 구간별 RMS 음량으로 파형을 계산합니다.
  nonisolated static func waveform(fromAudioFileAt url: URL, bucketCount: Int) -> [Float] {
    let fallback = Array(repeating: Float(0.3), count: bucketCount)
    guard
      let file = try? AVAudioFile(forReading: url),
      file.length > 0,
      let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
    else { return fallback }

    do { try file.read(into: buffer) } catch { return fallback }

    guard let channelData = buffer.floatChannelData else { return fallback }
    let channelCount = Int(buffer.format.channelCount)
    let sampleCount = Int(buffer.frameLength)
    guard sampleCount > 0 else { return fallback }

    let samplesPerBucket = max(1, sampleCount / bucketCount)
    var rmsPerBucket: [Float] = []
    rmsPerBucket.reserveCapacity(bucketCount)
    for bucketIndex in 0..<bucketCount {
      let start = bucketIndex * samplesPerBucket
      let end = bucketIndex == bucketCount - 1 ? sampleCount : min(sampleCount, start + samplesPerBucket)
      guard start < end else {
        rmsPerBucket.append(rmsPerBucket.last ?? 0)
        continue
      }
      var sumSquares: Float = 0
      for frame in start..<end {
        var sample: Float = 0
        for channel in 0..<channelCount { sample += channelData[channel][frame] }
        sample /= Float(channelCount)
        sumSquares += sample * sample
      }
      rmsPerBucket.append(sqrt(sumSquares / Float(end - start)))
    }

    // 하나의 큰 소리(정지 버튼 소리 등)가 기준이 되면 나머지가 모두 낮게 눌리므로,
    // 최대값 대신 상위 5% 지점을 기준으로 삼고 작은 소리도 보이도록 완만한 곡선을 적용한다.
    let sorted = rmsPerBucket.sorted()
    let reference = sorted[min(sorted.count - 1, Int(Float(sorted.count - 1) * 0.95))]
    guard reference > 0.0001 else { return fallback }
    return rmsPerBucket.map { rms in
      let ratio = min(1, rms / reference)
      return max(0.12, min(1, pow(ratio, 0.6)))
    }
  }
}
