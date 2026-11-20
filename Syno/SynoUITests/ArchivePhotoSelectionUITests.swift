import XCTest

/// 아카이브 사진 목록의 "선택하기"로 여러 장을 골라 삭제하는 흐름을 고정하는 UI 테스트입니다 (#142).
/// 샘플 채팅에는 사진이 4장 있습니다(UITestFixtureSeeder).
final class ArchivePhotoSelectionUITests: XCTestCase {
  private let contactName = "테스트 연락처"

  private var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UITestFixtures"]
    app.launch()
  }

  @MainActor
  func testSelectingPhotosShowsDeletionConfirmation() throws {
    openPhotoArchive()

    // 길게 눌러 "선택하기" → 그 사진이 선택된 채로 선택 모드가 시작된다.
    let firstPhoto = app.buttons.matching(identifier: "사진 크게 보기").firstMatch
    XCTAssertTrue(firstPhoto.waitForExistence(timeout: 5), "사진 목록이 없습니다")
    firstPhoto.press(forDuration: 1.0)
    let selectAction = app.buttons["선택하기"]
    XCTAssertTrue(selectAction.waitForExistence(timeout: 3), "길게 누르기 메뉴에 선택하기가 없습니다")
    selectAction.tap()

    XCTAssertTrue(app.staticTexts["1개 선택"].waitForExistence(timeout: 3), "선택 모드가 시작되지 않았습니다")
    XCTAssertTrue(app.buttons["선택된 사진"].exists)

    // 다른 사진을 누르면 미리보기로 가지 않고 선택이 늘어난다.
    let otherPhoto = app.buttons["사진 선택"].firstMatch
    XCTAssertTrue(otherPhoto.waitForExistence(timeout: 3))
    otherPhoto.tap()
    XCTAssertTrue(app.staticTexts["2개 선택"].waitForExistence(timeout: 3), "사진을 눌러 선택하지 못했습니다")

    // 삭제를 누르면 선택한 장수로 확인창이 뜬다.
    app.buttons["선택한 메시지 삭제"].tap()
    let confirmation = app.staticTexts.containing(
      NSPredicate(format: "label CONTAINS %@", "2장의 사진을")
    ).firstMatch
    XCTAssertTrue(confirmation.waitForExistence(timeout: 3), "삭제 확인창이 뜨지 않았습니다")
  }

  @MainActor
  func testCancelEndsSelectionMode() throws {
    openPhotoArchive()

    let firstPhoto = app.buttons.matching(identifier: "사진 크게 보기").firstMatch
    XCTAssertTrue(firstPhoto.waitForExistence(timeout: 5), "사진 목록이 없습니다")
    firstPhoto.press(forDuration: 1.0)
    let selectAction = app.buttons["선택하기"]
    XCTAssertTrue(selectAction.waitForExistence(timeout: 3))
    selectAction.tap()
    XCTAssertTrue(app.staticTexts["1개 선택"].waitForExistence(timeout: 3))

    app.navigationBars.buttons["취소"].tap()

    XCTAssertTrue(app.staticTexts["1개 선택"].waitForNonExistence(timeout: 3), "취소했는데 선택 모드가 남아 있습니다")
    XCTAssertEqual(app.buttons.matching(identifier: "사진 크게 보기").count, 4, "취소했는데 사진 수가 바뀌었습니다")
  }

  /// 노트 탭 → 샘플 채팅 → 아카이브 → 사진 "더 보기"로 이동합니다.
  @MainActor
  private func openPhotoArchive() {
    let notesTab = app.tabBars.buttons["Notes"].exists ? app.tabBars.buttons["Notes"] : app.buttons["Notes"]
    XCTAssertTrue(notesTab.waitForExistence(timeout: 5), "노트 탭을 찾지 못했습니다")
    notesTab.tap()

    let contactRow = app.buttons[contactName].firstMatch
    XCTAssertTrue(contactRow.waitForExistence(timeout: 5), "샘플 연락처를 찾지 못했습니다")
    contactRow.tap()

    let archiveButton = app.buttons["아카이브"]
    XCTAssertTrue(archiveButton.waitForExistence(timeout: 5), "아카이브 버튼을 찾지 못했습니다")
    archiveButton.tap()

    let morePhotos = app.buttons["archive.more.photos"]
    XCTAssertTrue(morePhotos.waitForExistence(timeout: 5), "사진 더 보기를 찾지 못했습니다")
    if !morePhotos.isHittable {
      app.swipeUp()
    }
    morePhotos.tap()
  }
}
