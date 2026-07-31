import FoundationModels
import XCTest
@testable import Syno

@available(iOS 26.0, *)
final class FoundationModelsLabelTranslationSpikeTests: XCTestCase {
  @MainActor
  func testVisionLabelKoreanTranslationQualityAndLatency() async throws {
    let labels = ["cat", "outdoor", "tableware"]
    let dictionary = StaticLabelDictionary()
    let model = SystemLanguageModel.default
    var report = [
      "runtime=\(ProcessInfo.processInfo.operatingSystemVersionString)",
      "availability=\(availabilityText(model.availability))",
      "staticDictionary=\(labels.map { "\($0)=\(dictionary.translation(for: $0) ?? "unmapped")" }.joined(separator: ", "))"
    ]

    guard model.isAvailable else {
      report.append("generationSkipped=true")
      report.append("reason=SystemLanguageModel is unavailable on this runtime")
      attach(report)
      return
    }

    #if targetEnvironment(simulator)
    report.append("generationSkipped=true")
    report.append(
      "reason=Simulator may report available without Model Catalog assets"
    )
    attach(report)
    #else
    let session = LanguageModelSession(
      model: model,
      instructions: """
      Translate English computer-vision labels into concise, natural Korean \
      search keywords. Return only one line per input in the exact format \
      English=Korean. Do not add explanations.
      """
    )
    let prompt = """
      Translate these labels:
      cat
      outdoor
      tableware
      """

    do {
      let coldStartedAt = Date()
      let coldResponse = try await session.respond(to: prompt)
      let coldMilliseconds = Int(
        Date().timeIntervalSince(coldStartedAt) * 1_000
      )
      report.append("coldDurationMs=\(coldMilliseconds)")
      report.append("coldResponse=\(coldResponse.content)")

      let warmStartedAt = Date()
      let warmResponse = try await session.respond(
        to: "Translate the same three labels again using the required format."
      )
      let warmMilliseconds = Int(
        Date().timeIntervalSince(warmStartedAt) * 1_000
      )
      report.append("warmDurationMs=\(warmMilliseconds)")
      report.append("warmResponse=\(warmResponse.content)")

      XCTAssertFalse(coldResponse.content.isEmpty)
      XCTAssertFalse(warmResponse.content.isEmpty)
    } catch {
      report.append("generationError=\(error)")
    }
    attach(report)
    #endif
  }

  private func availabilityText(
    _ availability: SystemLanguageModel.Availability
  ) -> String {
    switch availability {
    case .available:
      "available"
    case .unavailable(let reason):
      switch reason {
      case .deviceNotEligible:
        "unavailable.deviceNotEligible"
      case .appleIntelligenceNotEnabled:
        "unavailable.appleIntelligenceNotEnabled"
      case .modelNotReady:
        "unavailable.modelNotReady"
      @unknown default:
        "unavailable.unknown"
      }
    }
  }

  private func attach(_ report: [String]) {
    let output = report.joined(separator: "\n")
    print("Foundation Models label translation spike\n\(output)")
    let attachment = XCTAttachment(string: output)
    attachment.name = "Foundation Models label translation spike"
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
