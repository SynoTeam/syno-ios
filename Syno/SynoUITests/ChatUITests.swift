import XCTest

/// 채팅 화면 동작을 확인하는 UI 테스트입니다 (#116에서 시뮬레이터로 직접 확인하던 항목).
/// 앱은 `-UITestFixtures` 인자로 메모리 저장소와 고정 샘플 데이터(UITestFixtureSeeder)로 시작합니다.
final class ChatUITests: XCTestCase {
  /// UITestFixtureSeeder.Text와 같은 값입니다.
  private enum Fixture {
    static let contactName = "테스트 연락처"
    static let oldestMessage = "첫 번째 메시지"
    static let latestMessage = "마지막 메시지"
  }

  private var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UITestFixtures"]
    app.launch()
  }

  @MainActor
  func testOpeningChatShowsLatestMessage() throws {
    openFixtureChat()

    XCTAssertTrue(app.staticTexts[Fixture.latestMessage].waitUntilHittable(timeout: 5))
  }

  @MainActor
  func testScrolledPositionStaysWhileIdle() throws {
    openFixtureChat()
    let messageList = app.scrollViews["chat.messageList"]
    let oldestMessage = app.staticTexts[Fixture.oldestMessage]

    for _ in 0..<20 where !oldestMessage.isHittable {
      messageList.swipeDown(velocity: .fast)
    }
    XCTAssertTrue(oldestMessage.isHittable, "맨 위까지 스크롤하지 못했습니다")
    // 빠른 스와이프의 관성이 끝난 위치를 기준으로 삼는다.
    let frameBeforeWaiting = try XCTUnwrap(oldestMessage.settledFrame(timeout: 5), "스크롤이 멈추지 않았습니다")

    // 사용자가 손을 뗀 뒤 앱이 스스로 위치를 바꾸지 않아야 한다.
    // 샘플 데이터는 메모리에서 즉시 로드되므로, 실제 앱의 늦은 미리보기·이미지 로드까지 재현하지는 않는다.
    Thread.sleep(forTimeInterval: 2)

    XCTAssertTrue(oldestMessage.isHittable)
    XCTAssertEqual(oldestMessage.frame.minY, frameBeforeWaiting.minY, accuracy: 2)
  }

  @MainActor
  func testTappingListBackgroundDismissesKeyboard() throws {
    openFixtureChat()
    let inputField = app.textFields["chat.inputField"].exists
      ? app.textFields["chat.inputField"]
      : app.textViews["chat.inputField"]

    inputField.tap()
    // CI 시뮬레이터는 처음 키보드를 띄울 때 느려서 넉넉히 기다린다 (#134).
    XCTAssertTrue(inputField.waitForKeyboardFocus(true, timeout: 10), "입력창에 포커스가 가지 않았습니다")
    // 시뮬레이터에 하드웨어 키보드가 연결되어 있으면 소프트웨어 키보드가 뜨지 않으므로, 뜬 경우에만 사라짐까지 확인한다.
    let keyboard = app.keyboards.firstMatch
    let wasKeyboardShown = keyboard.waitForExistence(timeout: 2)

    // 말풍선은 오른쪽에 붙어 있으므로 왼쪽 빈 곳을 누른다.
    app.scrollViews["chat.messageList"]
      .coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.4))
      .tap()

    XCTAssertTrue(inputField.waitForKeyboardFocus(false, timeout: 10), "바탕을 눌러도 입력창 포커스가 풀리지 않았습니다")
    if wasKeyboardShown {
      XCTAssertTrue(keyboard.waitForNonExistence(timeout: 3), "바탕을 눌러도 키보드가 내려가지 않았습니다")
    }
  }

  @MainActor
  func testCopyingMessageShowsToastWithoutKeyboard() throws {
    openFixtureChat()
    let latestMessage = app.staticTexts[Fixture.latestMessage]
    XCTAssertTrue(latestMessage.waitUntilHittable(timeout: 5))

    latestMessage.press(forDuration: 1)
    let copyButton = app.buttons["복사하기"]
    XCTAssertTrue(copyButton.waitForExistence(timeout: 3))
    copyButton.tap()

    // 토스트는 2.5초 뒤 사라진다. 나타난 뒤 다시 찾아 문구를 읽으면 느린 CI에서 이미 사라져 있으므로,
    // 식별자와 문구를 한 번의 대기 조건으로 확인한다 (#134).
    // 식별자는 안쪽 아이콘·글자에도 함께 붙고 요소 종류도 환경마다 달리 잡혀 종류를 한정하지 않는다.
    let toast = app.descendants(matching: .any)
      .matching(NSPredicate(format: "identifier == %@ AND label == %@", "toast", "노트가 복사되었습니다"))
      .firstMatch
    XCTAssertTrue(toast.waitForExistence(timeout: 5), "복사 토스트가 나타나지 않았습니다")
    XCTAssertFalse(app.keyboards.firstMatch.exists, "복사 후 키보드가 올라왔습니다")
  }

  /// 노트 탭에서 샘플 연락처의 채팅방으로 들어갑니다.
  @MainActor
  private func openFixtureChat() {
    let notesTab = app.tabBars.buttons["Notes"].exists ? app.tabBars.buttons["Notes"] : app.buttons["Notes"]
    XCTAssertTrue(notesTab.waitForExistence(timeout: 5), "노트 탭을 찾지 못했습니다")
    notesTab.tap()

    // 노트 목록의 행은 버튼으로 노출된다.
    let contactRow = app.buttons[Fixture.contactName].firstMatch
    XCTAssertTrue(contactRow.waitForExistence(timeout: 5), "샘플 연락처를 찾지 못했습니다")
    contactRow.tap()

    XCTAssertTrue(app.scrollViews["chat.messageList"].waitForExistence(timeout: 5), "채팅방이 열리지 않았습니다")
  }
}

private extension XCUIElement {
  func waitUntilHittable(timeout: TimeInterval) -> Bool {
    let predicate = NSPredicate(format: "exists == true AND hittable == true")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
    return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
  }

  /// 0.3초 간격으로 위치를 재서 두 번 연속 같으면 멈춘 것으로 보고 그 위치를 돌려줍니다.
  func settledFrame(timeout: TimeInterval) -> CGRect? {
    let deadline = Date().addingTimeInterval(timeout)
    var previousFrame = frame
    while Date() < deadline {
      Thread.sleep(forTimeInterval: 0.3)
      let currentFrame = frame
      if abs(currentFrame.minY - previousFrame.minY) < 0.5 {
        return currentFrame
      }
      previousFrame = currentFrame
    }
    return nil
  }

  /// 소프트웨어 키보드 표시 여부는 시뮬레이터 설정에 따라 달라서, 입력창 포커스로 판정합니다.
  func waitForKeyboardFocus(_ hasFocus: Bool, timeout: TimeInterval) -> Bool {
    let predicate = NSPredicate(format: "hasKeyboardFocus == %@", NSNumber(value: hasFocus))
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
    return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
  }
}
