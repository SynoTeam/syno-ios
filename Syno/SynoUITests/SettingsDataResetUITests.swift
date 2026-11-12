import XCTest

/// 설정 → 데이터 초기화의 확인 단계를 고정하는 UI 테스트입니다 (#130).
/// 확인창에서 삭제 범위를 알리고, 취소하면 아무것도 지우지 않아야 합니다.
final class SettingsDataResetUITests: XCTestCase {
  /// UITestFixtureSeeder의 내 프로필과 연락처 이름입니다.
  private enum Fixture {
    static let myName = "테스터"
    static let contactName = "테스트 연락처"
  }

  private var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UITestFixtures"]
    app.launch()
  }

  @MainActor
  func testDataResetShowsWarningBeforeDeleting() throws {
    openSettings()

    XCTAssertFalse(app.buttons["로그아웃"].exists, "로그인이 없는 앱에 로그아웃 버튼이 남아 있습니다")
    let resetButton = app.buttons["데이터 초기화"]
    XCTAssertTrue(resetButton.waitForExistence(timeout: 3), "데이터 초기화 버튼을 찾지 못했습니다")
    resetButton.tap()

    XCTAssertTrue(app.staticTexts["데이터를 초기화하시겠습니까?"].waitForExistence(timeout: 3))
    let warning = app.staticTexts.containing(
      NSPredicate(format: "label CONTAINS %@", "다른 기기에서도 삭제되며, 되돌릴 수 없습니다")
    ).firstMatch
    XCTAssertTrue(warning.exists, "삭제 범위와 되돌릴 수 없음을 알리는 문구가 없습니다")
    XCTAssertTrue(app.buttons["초기화"].exists)
  }

  @MainActor
  func testCancellingDataResetKeepsData() throws {
    openSettings()

    let resetButton = app.buttons["데이터 초기화"]
    XCTAssertTrue(resetButton.waitForExistence(timeout: 3), "데이터 초기화 버튼을 찾지 못했습니다")
    resetButton.tap()
    let cancelButton = app.buttons["취소"]
    XCTAssertTrue(cancelButton.waitForExistence(timeout: 3))
    cancelButton.tap()

    // 초기화가 시작되지 않았는지 보고, 설정 → 내 프로필 → 연락처 목록으로 돌아가 데이터가 남아 있는지 본다.
    XCTAssertTrue(app.staticTexts["데이터를 초기화하시겠습니까?"].waitForNonExistence(timeout: 3))
    XCTAssertFalse(app.staticTexts["초기화 중"].waitForExistence(timeout: 2), "취소했는데 초기화가 시작됐습니다")
    goBack()
    XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 3), "내 프로필로 돌아가지 못했습니다")
    goBack()
    // 연락처 행은 버튼으로 잡힌다.
    let contactRow = app.buttons.containing(
      NSPredicate(format: "label CONTAINS %@", Fixture.contactName)
    ).firstMatch
    XCTAssertTrue(contactRow.waitForExistence(timeout: 5), "취소했는데 연락처가 사라졌습니다")
  }

  /// 앱 공통 뒤로 가기 버튼(SynoBackButton)을 누릅니다.
  @MainActor
  private func goBack() {
    let backButton = app.buttons["뒤로"].firstMatch
    XCTAssertTrue(backButton.waitForExistence(timeout: 3), "뒤로 버튼을 찾지 못했습니다")
    backButton.tap()
  }

  /// 연락처 탭 → 내 프로필 → 설정으로 이동합니다.
  @MainActor
  private func openSettings() {
    let myProfile = app.buttons.containing(
      NSPredicate(format: "label CONTAINS %@", Fixture.myName)
    ).firstMatch
    XCTAssertTrue(myProfile.waitForExistence(timeout: 5), "내 프로필을 찾지 못했습니다")
    myProfile.tap()

    let settingsButton = app.buttons["Settings"]
    XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "설정 버튼을 찾지 못했습니다")
    settingsButton.tap()

    XCTAssertTrue(app.staticTexts["앱 설정"].waitForExistence(timeout: 5), "설정 화면이 열리지 않았습니다")
  }
}
