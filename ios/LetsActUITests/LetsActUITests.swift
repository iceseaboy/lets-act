import XCTest

final class LetsActUITests: XCTestCase {
    @MainActor func testChildHomeAndOffBookDoNotLeakHiddenLine() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["continue-practice"].waitForExistence(timeout: 10))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Child home"; screenshot.lifetime = .keepAlways; add(screenshot)
        let mode = app.buttons["mode-off_book"]
        if !mode.isHittable { app.swipeUp() }
        mode.tap()
        XCTAssertTrue(app.staticTexts["Your turn"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Hello, little star. How did you get here?"].exists)
        app.buttons["Hint"].tap()
        XCTAssertTrue(app.staticTexts["Hello,…"].exists)
        let player = XCTAttachment(screenshot: app.screenshot())
        player.name = "Off book player"; player.lifetime = .keepAlways; add(player)
        app.buttons["End practice"].tap()
    }

    @MainActor func testDirectorRequiresGate() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        app.buttons["Parent and director area"].tap()
        XCTAssertTrue(app.staticTexts["A moment for the grown-ups"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Create a show"].exists)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["continue-practice"].exists)
    }

    @MainActor func testDirectorCanImportReviewAndAssignMultipleRoles() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        app.buttons["Parent and director area"].tap()
        let question = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", " × ")).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        let numbers = question.label.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
        XCTAssertEqual(numbers.count, 2)
        let answer = app.textFields["parent-answer"]
        answer.tap(); answer.typeText(String(numbers[0] * numbers[1]))
        app.buttons["Unlock director area"].tap()
        XCTAssertTrue(app.buttons["Create a show"].waitForExistence(timeout: 5))
        app.buttons["Create a show"].tap()
        app.textFields["show-title"].tap(); app.textFields["show-title"].typeText("Garden rehearsal")
        app.textViews["script-text"].tap(); app.textViews["script-text"].typeText("SCENE 1: Garden\nLUNA: Hello, star!\nSTAR: Hello, Luna!")
        app.buttons["Done editing"].tap()
        app.swipeUp()
        let local = app.buttons["Review with local parsing"]
        if !local.isHittable { app.swipeUp() }
        local.tap()
        app.buttons["Cast & roles"].tap()
        app.switches["Child plays LUNA"].tap()
        app.switches["Child plays STAR"].tap()
        app.buttons["Confirm"].tap()
        app.buttons["I reviewed this — ready to practice"].tap()
        XCTAssertTrue(app.staticTexts["Garden rehearsal"].firstMatch.waitForExistence(timeout: 5))
        let open = app.buttons["Open this show in child mode"]
        if !open.isHittable { app.swipeUp() }
        open.tap()
        XCTAssertTrue(app.buttons["continue-practice"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Luna & Star"].exists)
    }
}
