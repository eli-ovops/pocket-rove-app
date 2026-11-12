import XCTest

final class EarthOnlineGuideUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func firstHistoryEntry(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-entry-")).firstMatch
    }

    private func captureEvidence(_ name: String, in app: XCUIApplication) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Visual — \(name)"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Accessibility hierarchy — \(name)"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }

    @MainActor
    func testAccessibility3InjectionIsObservable() throws {
        let app = XCUIApplication()
        app.launchEnvironment["EARTH_GUIDE_DYNAMIC_TYPE_VERIFY"] = "1"
        app.launchArguments += ["-EarthGuideDebugRoute", "today"]
        app.launch()

        let dynamicTypeProbe = app.staticTexts["ui-test-dynamic-type"]
        XCTAssertTrue(dynamicTypeProbe.waitForExistence(timeout: 5))
        XCTAssertEqual(dynamicTypeProbe.label, "accessibility3")
    }

    @MainActor
    func testFirstGuideToTodayCompletionHistoryUndoAndPreferences() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["EARTH_GUIDE_UI_TEST_RUN_ID"] = "workflow-restart-v1"
        app.launchEnvironment["UI_TEST_RESET"] = "1"
        app.launchArguments += ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans", "-EarthGuideUITest", "1"]
        app.launch()
        let guideID = app.textFields["onboarding-guide-id"]
        XCTAssertTrue(guideID.waitForExistence(timeout: 5))
        captureEvidence("Onboarding", in: app)
        guideID.tap(); guideID.typeText("ui-guide")
        app.keyboards.buttons["完成"].tap()
        app.buttons["onboarding-start"].tap()
        XCTAssertTrue(app.tabBars.buttons["今日"].waitForExistence(timeout: 5))
        let taskButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "today-task-"))
        let firstTask = taskButtons.firstMatch
        XCTAssertTrue(firstTask.waitForExistence(timeout: 5))
        let taskUnderTest = app.buttons[firstTask.identifier]
        XCTAssertFalse(taskUnderTest.identifier.isEmpty)
        let appFrame = app.frame
        let contentFrame = CGRect(
            x: appFrame.minX,
            y: appFrame.minY,
            width: appFrame.width,
            height: app.tabBars.firstMatch.frame.minY - appFrame.minY
        )
        let visibleTaskButtons = taskButtons.allElementsBoundByIndex
            .filter { contentFrame.contains(CGPoint(x: $0.frame.midX, y: $0.frame.midY)) }
            .sorted { $0.frame.minY < $1.frame.minY }
        XCTAssertGreaterThanOrEqual(visibleTaskButtons.count, 2)
        for taskButton in visibleTaskButtons {
            XCTAssertFalse(taskButton.frame.isEmpty)
            XCTAssertTrue(taskButton.isHittable)
            XCTAssertGreaterThanOrEqual(taskButton.frame.height, 44)
            XCTAssertLessThan(taskButton.frame.height, appFrame.height / 2)
        }
        for (upper, lower) in zip(visibleTaskButtons, visibleTaskButtons.dropFirst()) {
            XCTAssertLessThanOrEqual(upper.frame.maxY, lower.frame.minY)
        }
        captureEvidence("Today", in: app)
        taskUnderTest.tap()
        XCTAssertTrue(taskUnderTest.label.contains("已完成"))
        app.tabBars.buttons["历史"].tap()
        XCTAssertTrue(firstHistoryEntry(in: app).waitForExistence(timeout: 5))
        captureEvidence("History", in: app)
        app.tabBars.buttons["设置"].tap()
        app.switches["settings-music"].tap(); app.switches["settings-sound"].tap()
        XCTAssertEqual(app.switches["settings-music"].value as? String, "1")
        XCTAssertEqual(app.switches["settings-sound"].value as? String, "1")
        captureEvidence("Settings", in: app)
        app.terminate(); app.launchEnvironment["UI_TEST_RESET"] = "0"; app.launch()
        app.tabBars.buttons["设置"].tap()
        let persistedGuideID = app.staticTexts["settings-guide-id"]
        XCTAssertTrue(persistedGuideID.waitForExistence(timeout: 5))
        XCTAssertTrue(persistedGuideID.label.contains("ui-guide"))
        XCTAssertEqual(app.switches["settings-music"].value as? String, "1")
        XCTAssertEqual(app.switches["settings-sound"].value as? String, "1")
        app.tabBars.buttons["历史"].tap()
        XCTAssertTrue(firstHistoryEntry(in: app).exists)
        app.tabBars.buttons["今日"].tap(); taskUnderTest.tap()
        app.tabBars.buttons["历史"].tap()
        XCTAssertFalse(firstHistoryEntry(in: app).exists)
        captureEvidence("Empty History", in: app)
        app.terminate()
        let reopenedApp = XCUIApplication()
        reopenedApp.launchEnvironment["UI_TESTING"] = "1"
        reopenedApp.launchEnvironment["EARTH_GUIDE_UI_TEST_RUN_ID"] = "workflow-restart-v1"
        reopenedApp.launchEnvironment["UI_TEST_RESET"] = "0"
        reopenedApp.launchArguments += ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans", "-EarthGuideUITest", "1"]
        reopenedApp.launch()
        reopenedApp.tabBars.buttons["历史"].tap()
        XCTAssertFalse(firstHistoryEntry(in: reopenedApp).exists)
    }
}
