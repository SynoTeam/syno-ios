import XCTest

/// 연락처 추가 → 그룹 선택 시트의 동작을 고정하는 UI 테스트입니다 (#122).
/// 시트 내부 구조를 리팩터링해도 같은 테스트가 통과해야 합니다.
final class GroupSelectionUITests: XCTestCase {
  /// UITestFixtureSeeder.Text.groupsInCustomOrder와 같은 값입니다.
  private enum Fixture {
    static let groupsInCustomOrder = ["스터디", "회사", "가족"]
  }

  private var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UITestFixtures"]
    app.launch()
  }

  @MainActor
  func testShowsNoneOptionAndGroupsInCustomOrder() throws {
    openGroupSelection()

    let names = ["선택 안 함"] + Fixture.groupsInCustomOrder
    let order = names
      .map { name -> (String, CGFloat) in
        let row = groupRow(name)
        XCTAssertTrue(row.waitForExistence(timeout: 3), "\(name) 행이 보이지 않습니다")
        return (name, row.frame.minY)
      }
      .sorted { $0.1 < $1.1 }
      .map(\.0)
    XCTAssertEqual(order, names)
  }

  @MainActor
  func testSelectingGroupAppliesItToForm() throws {
    openGroupSelection()

    groupRow("회사").tap()
    sheetApplyButton.tap()

    XCTAssertTrue(app.buttons["회사"].waitForExistence(timeout: 3), "선택한 그룹이 폼에 적용되지 않았습니다")
  }

  @MainActor
  func testCreatingNewGroupSelectsItAndAppliesOnDone() throws {
    openGroupSelection()

    app.buttons["그룹 추가하기"].tap()
    let nameField = app.textFields["그룹 이름"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 3))
    nameField.typeText("동아리")
    // 입력 중에 상단 완료를 눌러도 그 그룹을 만들어 적용해야 한다.
    sheetApplyButton.tap()

    XCTAssertTrue(app.buttons["동아리"].waitForExistence(timeout: 3), "새 그룹이 폼에 적용되지 않았습니다")
  }

  @MainActor
  func testSelectingOtherGroupWhileTypingAppliesLastSelection() throws {
    openGroupSelection()

    app.buttons["그룹 추가하기"].tap()
    let nameField = app.textFields["그룹 이름"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 3))
    nameField.typeText("임시")
    groupRow("가족").tap()
    sheetApplyButton.tap()

    XCTAssertTrue(app.buttons["가족"].waitForExistence(timeout: 3), "마지막으로 고른 그룹이 적용되지 않았습니다")

    // 입력하다 그만둔 이름으로는 그룹이 만들어지지 않아야 한다.
    app.buttons["가족"].tap()
    XCTAssertTrue(groupRow("가족").waitForExistence(timeout: 3))
    XCTAssertFalse(groupRow("임시").exists)
  }

  /// 시트 상단의 완료 버튼입니다. 뒤쪽 연락처 추가 화면에도 "완료"가 있어 식별자로 찾습니다.
  private var sheetApplyButton: XCUIElement {
    app.buttons["sheetHeader.apply"].firstMatch
  }

  /// 연락처 탭의 + 메뉴에서 연락처 추가하기를 열고, 그룹 선택 시트를 엽니다.
  @MainActor
  private func openGroupSelection() {
    let addMenu = app.buttons["Add Contact"].firstMatch
    XCTAssertTrue(addMenu.waitForExistence(timeout: 5), "연락처 추가 메뉴를 찾지 못했습니다")
    addMenu.tap()

    let addContact = app.buttons["연락처 추가하기"]
    XCTAssertTrue(addContact.waitForExistence(timeout: 3), "연락처 추가하기 메뉴를 찾지 못했습니다")
    addContact.tap()

    let groupField = app.buttons["그룹 선택하기"]
    XCTAssertTrue(groupField.waitForExistence(timeout: 5), "그룹 선택 행을 찾지 못했습니다")
    groupField.tap()

    XCTAssertTrue(app.staticTexts["그룹 선택"].waitForExistence(timeout: 3), "그룹 선택 시트가 열리지 않았습니다")
  }

  /// 시트의 그룹 행입니다. 행 앞의 체크 아이콘 때문에 라벨이 이름으로 끝나는 버튼으로 찾습니다.
  private func groupRow(_ name: String) -> XCUIElement {
    app.buttons.matching(NSPredicate(format: "label == %@ OR label ENDSWITH %@", name, ", \(name)")).firstMatch
  }
}
