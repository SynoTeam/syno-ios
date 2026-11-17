import XCTest

/// 노트 저장공간 관리의 iCloud 동기화 카드를 고정하는 UI 테스트입니다 (#136).
/// UI 테스트 앱은 iCloud에 로그인된 것으로 고정하고, 동기화 설정은 실행할 때마다 기본값(켜짐)으로 시작합니다.
final class NoteStorageCloudSyncUITests: XCTestCase {
  /// UITestFixtureSeeder의 내 프로필 이름입니다.
  private let myName = "테스터"

  private var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UITestFixtures"]
    app.launch()
  }

  @MainActor
  func testStorageSheetShowsCloudSyncCard() throws {
    openStorageSheet()

    let syncToggle = app.switches["iCloud 자동 동기화"]
    XCTAssertTrue(syncToggle.waitForExistence(timeout: 5), "iCloud 자동 동기화 토글이 없습니다")
    XCTAssertEqual(syncToggle.value as? String, "1", "처음에는 동기화가 켜져 있어야 합니다")
    XCTAssertTrue(app.staticTexts["마지막 동기화"].exists)
    XCTAssertTrue(app.staticTexts["아직 동기화 기록이 없습니다"].exists)
    XCTAssertTrue(app.buttons["동기화 상태 새로고침"].exists)
  }

  @MainActor
  func testTurningSyncOffAsksForRestart() throws {
    openStorageSheet()

    let syncToggle = app.switches["iCloud 자동 동기화"]
    XCTAssertTrue(syncToggle.waitForExistence(timeout: 5), "iCloud 자동 동기화 토글이 없습니다")
    // 토글은 iCloud 상태 확인이 끝난 뒤에 활성화되므로, 활성화될 때까지 기다린다.
    let enabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: syncToggle)
    wait(for: [enabled], timeout: 5)
    syncToggle.switches.firstMatch.tap()

    XCTAssertTrue(
      app.staticTexts["앱을 다시 시작하면 동기화가 꺼집니다."].waitForExistence(timeout: 3),
      "동기화를 끈 뒤 다시 시작 안내가 없습니다"
    )
    let offDescription = app.staticTexts.containing(
      NSPredicate(format: "label CONTAINS %@", "이 기기에만 저장되며")
    ).firstMatch
    XCTAssertTrue(offDescription.exists, "꺼짐 설명 문구가 없습니다")
  }

  /// 연락처 탭 → 내 프로필 → 설정 → 노트 저장공간 관리 시트를 엽니다.
  @MainActor
  private func openStorageSheet() {
    let myProfile = app.buttons.containing(
      NSPredicate(format: "label CONTAINS %@", myName)
    ).firstMatch
    XCTAssertTrue(myProfile.waitForExistence(timeout: 5), "내 프로필을 찾지 못했습니다")
    myProfile.tap()

    let settingsButton = app.buttons["Settings"]
    XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "설정 버튼을 찾지 못했습니다")
    settingsButton.tap()

    let storageRow = app.buttons.containing(
      NSPredicate(format: "label CONTAINS %@", "노트 저장공간 관리")
    ).firstMatch
    XCTAssertTrue(storageRow.waitForExistence(timeout: 5), "노트 저장공간 관리를 찾지 못했습니다")
    storageRow.tap()

    XCTAssertTrue(
      app.staticTexts["노트 저장공간 관리"].waitForExistence(timeout: 5),
      "노트 저장공간 관리 시트가 열리지 않았습니다"
    )
  }
}
