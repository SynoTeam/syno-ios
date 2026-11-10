import XCTest

/// 노트 → 그룹 편집하기 시트의 동작을 고정하는 UI 테스트입니다 (#120).
/// 시트 내부 구조를 리팩터링해도 같은 테스트가 통과해야 합니다.
final class GroupManagementUITests: XCTestCase {
  /// UITestFixtureSeeder.Text.groupsInCustomOrder와 같은 값입니다.
  private enum Fixture {
    static let groupsInCustomOrder = ["스터디", "회사", "가족"]
    static let groupsInAlphabeticalOrder = ["가족", "스터디", "회사"]
  }

  private var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UITestFixtures"]
    app.launch()
  }

  @MainActor
  func testOpeningShowsAllGroups() throws {
    openGroupManagement()

    for name in Fixture.groupsInCustomOrder {
      XCTAssertTrue(groupRow(name).waitForExistence(timeout: 3), "\(name) 그룹이 보이지 않습니다")
    }
  }

  @MainActor
  func testAlphabeticalSortShowsGroupsByName() throws {
    openGroupManagement()

    app.buttons["가나다순"].tap()

    XCTAssertEqual(visibleGroupOrder(), Fixture.groupsInAlphabeticalOrder)
  }

  @MainActor
  func testCustomSortShowsSavedOrder() throws {
    openGroupManagement()

    app.buttons["사용자 설정 순"].tap()

    XCTAssertEqual(visibleGroupOrder(), Fixture.groupsInCustomOrder)
  }

  @MainActor
  func testDeletingGroupRemovesItWithoutAcknowledgement() throws {
    openGroupManagement()
    XCTAssertTrue(groupRow("회사").waitForExistence(timeout: 3))

    app.buttons["회사 그룹 삭제"].tap()
    // 체크박스 확인 없이 바로 누를 수 있어야 한다.
    let confirmButton = app.buttons["삭제"]
    XCTAssertTrue(confirmButton.waitForExistence(timeout: 3))
    XCTAssertTrue(confirmButton.isEnabled)
    confirmButton.tap()

    XCTAssertTrue(groupRow("회사").waitForNonExistence(timeout: 3), "삭제한 그룹이 남아 있습니다")
    XCTAssertTrue(groupRow("스터디").exists)
    XCTAssertTrue(groupRow("가족").exists)
  }

  /// 노트 탭의 ⋯ 메뉴에서 그룹 편집하기를 엽니다.
  @MainActor
  private func openGroupManagement() {
    let notesTab = app.tabBars.buttons["Notes"]
    XCTAssertTrue(notesTab.waitForExistence(timeout: 5), "노트 탭을 찾지 못했습니다")
    notesTab.tap()

    let menuButton = app.buttons["노트 정렬"].firstMatch
    XCTAssertTrue(menuButton.waitForExistence(timeout: 5), "노트 메뉴를 찾지 못했습니다")
    menuButton.tap()

    let editGroupsButton = app.buttons["그룹 편집하기"]
    XCTAssertTrue(editGroupsButton.waitForExistence(timeout: 3), "그룹 편집하기 메뉴를 찾지 못했습니다")
    editGroupsButton.tap()

    XCTAssertTrue(app.staticTexts["그룹 편집"].waitForExistence(timeout: 3), "그룹 편집 시트가 열리지 않았습니다")
  }

  /// 시트 안의 그룹 행입니다. 뒤쪽 노트 화면의 필터 칩에도 같은 이름이 있어서,
  /// 시트에만 있는 "<이름> 그룹 삭제" 버튼으로 행을 찾습니다.
  private func groupRow(_ name: String) -> XCUIElement {
    app.buttons["\(name) 그룹 삭제"]
  }

  /// 화면 위에서 아래 순서로 보이는 그룹 이름입니다.
  private func visibleGroupOrder() -> [String] {
    Fixture.groupsInCustomOrder
      .map { name -> (String, CGFloat) in
        let deleteButton = app.buttons["\(name) 그룹 삭제"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "\(name) 그룹을 찾지 못했습니다")
        return (name, deleteButton.frame.minY)
      }
      .sorted { $0.1 < $1.1 }
      .map(\.0)
  }
}
