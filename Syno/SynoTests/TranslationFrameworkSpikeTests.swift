import Translation
import XCTest

final class TranslationFrameworkSpikeTests: XCTestCase {
  @MainActor
  func testEnglishVisionLabelTranslationSpike() async throws {
    let source = Locale.Language(identifier: "en")
    let target = Locale.Language(identifier: "ko")
    var report = [
      "runtime=\(ProcessInfo.processInfo.operatingSystemVersionString)",
      "source=\(source.minimalIdentifier)",
      "target=\(target.minimalIdentifier)"
    ]

    #if targetEnvironment(simulator)
    report.append("runtimeTranslationSkipped=true")
    report.append("reason=Apple Translation APIs do not function in Simulator")
    if #available(iOS 26.0, *) {
      _ = makeInstalledSession
      report.append("viewFreeInstalledSessionCompiles=true")
    }
    #else
    let availability = LanguageAvailability()
    let status = await availability.status(from: source, to: target)
    report.append("languagePairStatus=\(statusText(status))")

    if #available(iOS 26.0, *), status == .installed {
      let session = TranslationSession(
        installedSource: source,
        target: target
      )
      report.append("viewFreeInstalledSession=true")
      report.append("canRequestDownloads=\(session.canRequestDownloads)")
      report.append("isReady=\(await session.isReady)")

      for label in ["cat", "outdoor", "tableware"] {
        do {
          let response = try await session.translate(label)
          report.append("\(label)=\(response.targetText)")
        } catch {
          report.append("\(label)Error=\(error)")
        }
      }
    } else {
      report.append("viewFreeTranslationRun=false")
      report.append("requiresUserApprovedLanguageDownload=\(status == .supported)")
    }
    #endif

    let output = report.joined(separator: "\n")
    print("Translation framework spike\n\(output)")
    let attachment = XCTAttachment(string: output)
    attachment.name = "Translation framework spike"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  @available(iOS 26.0, *)
  private func makeInstalledSession() -> TranslationSession {
    TranslationSession(
      installedSource: Locale.Language(identifier: "en"),
      target: Locale.Language(identifier: "ko")
    )
  }

  private func statusText(_ status: LanguageAvailability.Status) -> String {
    switch status {
    case .installed:
      "installed"
    case .supported:
      "supported"
    case .unsupported:
      "unsupported"
    @unknown default:
      "unknown"
    }
  }
}
