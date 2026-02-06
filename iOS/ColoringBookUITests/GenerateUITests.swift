import XCTest

final class GenerateUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func testGenerateButtonDisabledWhenEmpty() {
        // Open generate sheet
        let generateButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        generateButton.tap()

        XCTAssertTrue(app.navigationBars["Generate Image"].waitForExistence(timeout: 3))

        // The Generate button in the form should be disabled when text field is empty
        let formGenerateButton = app.buttons["Generate"]
        XCTAssertTrue(formGenerateButton.waitForExistence(timeout: 3))
        XCTAssertFalse(formGenerateButton.isEnabled)
    }

    func testCancelDismissesSheet() {
        // Open generate sheet
        let generateButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        generateButton.tap()

        XCTAssertTrue(app.navigationBars["Generate Image"].waitForExistence(timeout: 3))

        // Tap cancel
        app.buttons["Cancel"].tap()

        // Sheet should dismiss, gallery title should be visible again
        XCTAssertTrue(app.navigationBars["Coloring Book"].waitForExistence(timeout: 3))
    }
}
