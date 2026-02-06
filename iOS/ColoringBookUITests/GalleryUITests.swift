import XCTest

final class GalleryUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func testGalleryDisplaysNavigationTitle() {
        XCTAssertTrue(app.navigationBars["Coloring Book"].waitForExistence(timeout: 5))
    }

    func testGenerateButtonExists() {
        let generateButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
    }

    func testTapGenerateOpensSheet() {
        let generateButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        generateButton.tap()

        XCTAssertTrue(app.navigationBars["Generate Image"].waitForExistence(timeout: 3))
    }

    func testSearchBarExists() {
        // Swipe down to reveal search bar
        app.swipeDown()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
    }
}
