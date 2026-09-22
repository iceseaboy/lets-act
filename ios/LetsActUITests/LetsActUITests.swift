import XCTest
import UIKit

final class LetsActUITests: XCTestCase {
    @MainActor private func launch() -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = UIDevice.current.userInterfaceIdiom == .pad ? .landscapeLeft : .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["continue-practice"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, "Control must remain reachable: \(element)")
    }

    @MainActor private func capture(_ name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor private func unlock(_ app: XCUIApplication) {
        app.buttons["Parent and director area"].tap()
        let question = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", " × ")).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        let numbers = question.label.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
        XCTAssertEqual(numbers.count, 2)
        let answer = app.textFields["parent-answer"]
        reveal(answer, in: app)
        answer.tap(); answer.typeText(String(numbers[0] * numbers[1]))
        XCTAssertTrue(app.buttons["Unlock director area"].isHittable)
        capture("Parent gate with keyboard", in: app)
        app.buttons["Unlock director area"].tap()
        XCTAssertTrue(app.buttons["Create a show"].waitForExistence(timeout: 5))
    }

    @MainActor private func importText(_ app: XCUIApplication, title: String) {
        app.buttons["Create a show"].tap()
        app.textFields["show-title"].tap(); app.textFields["show-title"].typeText(title)
        app.textViews["script-text"].tap()
        app.textViews["script-text"].typeText("SCENE 1: Garden\nLUNA: Hello, star!\nSTAR: Hello, Luna!")
        app.buttons["Done editing"].tap()
        let local = app.buttons["Review with local parsing"]
        reveal(local, in: app); local.tap()
        XCTAssertTrue(app.buttons["Cast & roles"].waitForExistence(timeout: 5))
    }

    @MainActor func testChildHomeAndOffBookDoNotLeakHiddenLine() throws {
        let app = launch()
        capture("Child home", in: app)
        let mode = app.buttons["mode-off_book"]
        reveal(mode, in: app); mode.tap()
        XCTAssertTrue(app.staticTexts["Your turn"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Hello, little star. How did you get here?"].exists)
        app.buttons["Hint"].tap()
        XCTAssertTrue(app.staticTexts["Hello,…"].exists)
        capture("Off book player", in: app)
        app.buttons["End practice"].tap()
    }

    @MainActor func testDirectorRequiresGate() throws {
        let app = launch()
        app.buttons["Parent and director area"].tap()
        XCTAssertTrue(app.staticTexts["A moment for the grown-ups"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Create a show"].exists)
        let answer = app.textFields["parent-answer"]
        reveal(answer, in: app); answer.tap(); answer.typeText("0")
        app.buttons["Unlock director area"].tap()
        XCTAssertFalse(app.buttons["Create a show"].exists)
        XCTAssertEqual(answer.value as? String, "Answer")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["continue-practice"].waitForExistence(timeout: 5))
    }

    @MainActor func testDirectorCanImportReviewAndAssignMultipleRoles() throws {
        let app = launch()
        unlock(app)
        importText(app, title: "Garden rehearsal")
        app.buttons["Cast & roles"].tap()
        app.switches["Child plays LUNA"].tap()
        let star = app.switches["Child plays STAR"]
        reveal(star, in: app); star.tap()
        app.buttons["Confirm"].tap()
        let confirm = app.buttons["I reviewed this — ready to practice"]
        reveal(confirm, in: app); confirm.tap()
        XCTAssertTrue(app.staticTexts["Garden rehearsal"].firstMatch.waitForExistence(timeout: 5))
        let open = app.buttons["Open this show in child mode"]
        reveal(open, in: app); open.tap()
        XCTAssertTrue(app.buttons["continue-practice"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Luna & Star"].exists)
        let mode = app.buttons["mode-off_book"]
        reveal(mode, in: app); mode.tap()
        XCTAssertTrue(app.staticTexts["Your turn"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Hello, star!"].exists)
        capture("Imported show in rehearsal", in: app)
        app.buttons["End practice"].tap()
        app.terminate()
        app.launchArguments.append("--preserve-ui-test-data")
        app.launch()
        XCTAssertTrue(app.buttons["continue-practice"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Luna & Star"].exists)
    }

    @MainActor func testDraftPersistsWithoutBecomingPlayable() throws {
        let app = launch()
        unlock(app)
        importText(app, title: "Unfinished garden")
        app.buttons["Save draft"].tap()
        XCTAssertTrue(app.staticTexts["Unfinished garden"].firstMatch.waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments.append("--preserve-ui-test-data")
        app.launch()
        XCTAssertTrue(app.buttons["Set the stage"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["continue-practice"].exists)
        unlock(app)
        let show = app.buttons["show-Unfinished garden"]
        if show.exists { show.tap() }
        let open = app.buttons["Open this show in child mode"]
        reveal(open, in: app)
        XCTAssertFalse(open.isEnabled)
        XCTAssertTrue(app.buttons["Review script & roles"].exists)
    }

    @MainActor func testBackgroundLocksDirectorAndPendingGate() throws {
        let app = launch()
        unlock(app)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["continue-practice"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Create a show"].exists)
        app.buttons["Parent and director area"].tap()
        XCTAssertTrue(app.textFields["parent-answer"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["continue-practice"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["parent-answer"].exists)
        XCTAssertFalse(app.buttons["Create a show"].exists)
    }
}
