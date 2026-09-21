import XCTest

final class LetsActUITests: XCTestCase {
    @MainActor func testChildHomeAndOffBookDoNotLeakHiddenLine() throws {
        let app = XCUIApplication()
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
        app.launch()
        app.buttons["Parent and director area"].tap()
        XCTAssertTrue(app.staticTexts["A moment for the grown-ups"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Create a show"].exists)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["continue-practice"].exists)
    }
}
