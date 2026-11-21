import XCTest

/// 아카이브 음성 목록에서 행을 눌러 재생 카드를 펼치고 접는 흐름을 고정하는 UI 테스트입니다 (#144).
/// 샘플 채팅에는 변환 텍스트가 있는 음성 메모가 3개 있습니다(UITestFixtureSeeder).
final class ArchiveVoiceMemoUITests: XCTestCase {
  private let contactName = "테스트 연락처"

  private var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UITestFixtures"]
    app.launch()
  }

  @MainActor
  func testTappingRowExpandsOnlyOnePlayerCard() throws {
    openVoiceArchive()

    let rows = app.buttons.matching(identifier: "archive.voice.row")
    XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5), "음성 목록 행이 없습니다")
    XCTAssertEqual(rows.count, 3)

    // 행을 누르면 재생 카드가 펼쳐지고 재생 버튼과 00:00이 보인다.
    rows.element(boundBy: 0).tap()
    XCTAssertTrue(app.buttons["재생"].waitForExistence(timeout: 3), "재생 카드가 펼쳐지지 않았습니다")
    XCTAssertTrue(app.staticTexts["00:00"].exists)
    XCTAssertEqual(rows.count, 2)

    // 다른 행을 누르면 앞의 카드는 접히고 카드는 하나만 남는다.
    rows.element(boundBy: 1).tap()
    XCTAssertTrue(app.buttons["재생"].waitForExistence(timeout: 3))
    XCTAssertEqual(app.buttons.matching(identifier: "재생").count, 1, "카드가 두 개 펼쳐져 있습니다")
    XCTAssertEqual(rows.count, 2)

    // 제목 부분을 누르면 접힌다.
    app.buttons["음성 메모 접기"].tap()
    XCTAssertTrue(app.buttons["재생"].waitForNonExistence(timeout: 3), "카드가 접히지 않았습니다")
    XCTAssertEqual(rows.count, 3)
  }

  @MainActor
  func testTranscriptButtonOpensTranscriptModal() throws {
    openVoiceArchive()

    let firstRow = app.buttons.matching(identifier: "archive.voice.row").firstMatch
    XCTAssertTrue(firstRow.waitForExistence(timeout: 5))
    firstRow.tap()

    let transcriptButton = app.buttons["변환 텍스트 보기"]
    XCTAssertTrue(transcriptButton.waitForExistence(timeout: 3))
    transcriptButton.tap()

    // 모달에 변환 텍스트가 보이고, X로 닫는다.
    let transcript = app.staticTexts.containing(
      NSPredicate(format: "label BEGINSWITH %@", "음성 메모 변환 결과")
    ).firstMatch
    XCTAssertTrue(transcript.waitForExistence(timeout: 3), "변환 텍스트 모달이 뜨지 않았습니다")

    app.buttons["닫기"].tap()
    XCTAssertTrue(transcript.waitForNonExistence(timeout: 3), "변환 텍스트 모달이 닫히지 않았습니다")
    XCTAssertTrue(app.buttons["재생"].exists, "모달을 닫은 뒤 재생 카드가 그대로여야 합니다")
  }

  @MainActor
  func testSelectingVoiceMemosShowsDeletionConfirmation() throws {
    openVoiceArchive()

    // 길게 눌러 "선택하기" → 그 메모가 선택된 채로 선택 모드가 시작된다.
    let firstRow = app.buttons.matching(identifier: "archive.voice.row").firstMatch
    XCTAssertTrue(firstRow.waitForExistence(timeout: 5))
    firstRow.press(forDuration: 1.0)
    let selectAction = app.buttons["선택하기"]
    XCTAssertTrue(selectAction.waitForExistence(timeout: 3), "길게 누르기 메뉴에 선택하기가 없습니다")
    XCTAssertTrue(app.buttons["복사하기"].exists)
    XCTAssertTrue(app.buttons["삭제하기"].exists)
    selectAction.tap()

    XCTAssertTrue(app.staticTexts["1개 선택"].waitForExistence(timeout: 3), "선택 모드가 시작되지 않았습니다")

    // 다른 행을 누르면 재생 카드가 펼쳐지지 않고 선택이 늘어난다.
    let rows = app.buttons.matching(identifier: "archive.voice.selectRow")
    XCTAssertEqual(rows.count, 3)
    rows.element(boundBy: 1).tap()
    XCTAssertTrue(app.staticTexts["2개 선택"].waitForExistence(timeout: 3), "행을 눌러 선택하지 못했습니다")
    XCTAssertFalse(app.buttons["재생"].exists)

    app.buttons["선택한 음성 메모 삭제"].tap()
    let confirmation = app.staticTexts.containing(
      NSPredicate(format: "label CONTAINS %@", "2개의 음성 메모를")
    ).firstMatch
    XCTAssertTrue(confirmation.waitForExistence(timeout: 3), "삭제 확인창이 뜨지 않았습니다")
  }

  @MainActor
  func testCloseButtonEndsVoiceSelection() throws {
    openVoiceArchive()

    let firstRow = app.buttons.matching(identifier: "archive.voice.row").firstMatch
    XCTAssertTrue(firstRow.waitForExistence(timeout: 5))
    firstRow.press(forDuration: 1.0)
    let selectAction = app.buttons["선택하기"]
    XCTAssertTrue(selectAction.waitForExistence(timeout: 3))
    selectAction.tap()
    XCTAssertTrue(app.staticTexts["1개 선택"].waitForExistence(timeout: 3))

    app.buttons["선택 끝내기"].tap()

    XCTAssertTrue(app.staticTexts["1개 선택"].waitForNonExistence(timeout: 3), "X를 눌렀는데 선택 모드가 남아 있습니다")
    XCTAssertEqual(app.buttons.matching(identifier: "archive.voice.row").count, 3)
  }

  /// 노트 탭 → 샘플 채팅 → 아카이브 → 사진 "더 보기" → 상단 "음성" 탭으로 이동합니다.
  @MainActor
  private func openVoiceArchive() {
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

    let voiceTab = app.buttons["음성"]
    XCTAssertTrue(voiceTab.waitForExistence(timeout: 5), "음성 탭을 찾지 못했습니다")
    voiceTab.tap()
  }
}
