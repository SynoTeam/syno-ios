import UIKit
import XCTest
@testable import Syno

final class VisionNoteImageAnalyzerTests: XCTestCase {
  @MainActor
  func testRecognizesTextFromDocumentStyleImage() async throws {
    let analyzer = VisionNoteImageAnalyzer()
    let imageData = try makeJPEG { bounds in
      UIColor.white.setFill()
      UIRectFill(bounds)
      ("MEETING 2026" as NSString).draw(
        at: CGPoint(x: 40, y: 90),
        withAttributes: [
          .font: UIFont.systemFont(ofSize: 64, weight: .bold),
          .foregroundColor: UIColor.black
        ]
      )
    }

    let result = try await analyzer.analyze(imageData: imageData)

    XCTAssertTrue(result.ocrText.localizedCaseInsensitiveContains("MEETING"))
  }

  @MainActor
  func testSolidColorImageAnalysisCompletesWithoutText() async throws {
    let analyzer = VisionNoteImageAnalyzer()
    let imageData = try makeJPEG { bounds in
      UIColor.black.setFill()
      UIRectFill(bounds)
    }

    let result = try await analyzer.analyze(imageData: imageData)

    XCTAssertTrue(result.ocrText.isEmpty)
  }

  @MainActor
  private func makeJPEG(
    drawing: (CGRect) -> Void
  ) throws -> Data {
    let bounds = CGRect(x: 0, y: 0, width: 800, height: 300)
    let image = UIGraphicsImageRenderer(size: bounds.size).image { _ in
      drawing(bounds)
    }
    return try XCTUnwrap(image.jpegData(compressionQuality: 0.9))
  }
}
