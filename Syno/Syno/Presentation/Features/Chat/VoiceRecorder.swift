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

  func start() async -> Bool {
    let granted = await AVAudioApplication.requestRecordPermission()
    guard granted else { return false }
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
      return true
    } catch { return false }
  }

  func stop() -> (data: Data, duration: TimeInterval, waveform: [Float])? {
    guard let recorder else { return nil }
    let url = recorder.url
    recorder.stop()
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    timer?.invalidate(); timer = nil
    isRecording = false
    let waveform = Self.waveform(fromAudioFileAt: url, bucketCount: 20)
    let result = (try? Data(contentsOf: url)).map { ($0, duration, waveform) }
    try? FileManager.default.removeItem(at: url)
    self.recorder = nil
    return result
  }

  /// 실시간 미터링(averagePower)은 입력창 파형 애니메이션 같은 라이브 표시용으로만 씁니다.
  /// AAC 인코더는 미터링 값을 매 폴링마다 갱신하지 않고 인코더 블록 단위로 드문드문 갱신하기 때문에,
  /// 저장용 파형은 이 값 대신 녹음이 끝난 뒤 실제 오디오 파일을 직접 읽어 계산합니다.
  private static let silenceFloorDb: Float = -50

  private func sampleLevel() {
    guard let recorder, let startedAt else { return }
    recorder.updateMeters()
    duration = Date().timeIntervalSince(startedAt)
    let power = max(Self.silenceFloorDb, recorder.averagePower(forChannel: 0))
    let normalized = max(0.08, min(1, (power - Self.silenceFloorDb) / -Self.silenceFloorDb))
    levels.append(CGFloat(normalized))
    if levels.count > 50 { levels.removeFirst() }
  }

  /// 녹음된 오디오 파일을 직접 읽어 구간별 RMS 음량으로 파형을 계산합니다.
  private static func waveform(fromAudioFileAt url: URL, bucketCount: Int) -> [Float] {
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

    // 클립 자체의 최대 음량을 기준으로 정규화해, 조용히 녹음해도 파형이 잘 보이게 합니다.
    let peak = rmsPerBucket.max() ?? 0
    guard peak > 0.0001 else { return fallback }
    return rmsPerBucket.map { max(0.12, min(1, ($0 / peak) * 0.85 + 0.15)) }
  }
}
