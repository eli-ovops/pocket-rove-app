import XCTest

final class EarthOnlineGuideUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testFirstGuideToTodayCompletionHistoryUndoAndPreferences() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans", "-EarthGuideUITest", "1"]
        app.launch()
        let guideID = app.textFields["onboarding-guide-id"]
        XCTAssertTrue(guideID.waitForExistence(timeout: 5))
        guideID.tap(); guideID.typeText("ui-guide")
        app.buttons["onboarding-start"].tap()
        XCTAssertTrue(app.otherElements["tab-today"].waitForExistence(timeout: 5))
        let firstTask = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "today-task-")).firstMatch
        XCTAssertTrue(firstTask.waitForExistence(timeout: 5))
        firstTask.tap()
        app.otherElements["tab-history"].tap()
        XCTAssertTrue(app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-entry-")).firstMatch.waitForExistence(timeout: 5))
        app.otherElements["tab-today"].tap(); firstTask.tap()
        app.otherElements["tab-history"].tap()
        XCTAssertFalse(app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-entry-")).firstMatch.exists)
        app.otherElements["tab-settings"].tap()
        app.switches["settings-music"].tap(); app.switches["settings-sound"].tap()
    }
}
