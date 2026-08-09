import Foundation
import Speech

actor SpeechNoteVoiceTranscriber: NoteVoiceTranscribing {
  enum TranscriptionError: LocalizedError {
    case unavailable, denied, emptyResult
    var errorDescription: String? {
      switch self { case .unavailable: "Speech recognition is unavailable"; case .denied: "Speech recognition permission was denied"; case .emptyResult: "Speech recognition returned no text" }
    }
  }

  func transcribe(audioData: Data) async throws -> NoteVoiceTranscriptResult {
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR")), recognizer.isAvailable else { throw TranscriptionError.unavailable }
    guard await requestAuthorization() else { throw TranscriptionError.denied }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
    defer { try? FileManager.default.removeItem(at: url) }
    try audioData.write(to: url, options: .atomic)
    let request = SFSpeechURLRecognitionRequest(url: url)
    request.shouldReportPartialResults = false
    let text: String = try await withCheckedThrowingContinuation { continuation in
      let lock = NSLock()
      var didResume = false
      recognizer.recognitionTask(with: request) { result, error in
        lock.lock()
        defer { lock.unlock() }
        guard !didResume else { return }
        if let error {
          didResume = true
          continuation.resume(throwing: error)
        } else if let result, result.isFinal {
          didResume = true
          continuation.resume(returning: result.bestTranscription.formattedString)
        }
      }
    }
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw TranscriptionError.emptyResult }
    return NoteVoiceTranscriptResult(text: text)
  }

  private func requestAuthorization() async -> Bool {
    await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
    }
  }
}
