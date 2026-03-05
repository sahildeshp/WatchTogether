import XCTest

/// UI tests for the Search tab flow.
/// Requires a signed-in session; inject launch args or use a pre-seeded test account
/// when running on CI. In development, these tests are validated interactively.
final class SearchFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-auth"]
        app.launch()
    }

    // MARK: - Search tab

    func testSearchTabAccessible() {
        let searchTab = app.tabBars.buttons["Search"]
        XCTAssertTrue(searchTab.waitForExistence(timeout: 5))
        searchTab.tap()
    }

    func testSearchBarPresent() {
        app.tabBars.buttons["Search"].tap()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
    }

    func testSearchPromptShownWhenQueryEmpty() {
        app.tabBars.buttons["Search"].tap()
        // The empty state prompt should be visible before any query is entered.
        let prompt = app.staticTexts["Search for a movie or TV show"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
    }

    func testTypingQueryShowsResultsOrLoading() {
        app.tabBars.buttons["Search"].tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Inception")

        // After typing, either results list or a loading spinner should appear.
        let hasList    = app.tables.firstMatch.waitForExistence(timeout: 8)
        let hasSpinner = app.activityIndicators.firstMatch.exists
        XCTAssertTrue(hasList || hasSpinner, "Expected results or loading indicator")
    }

    // MARK: - Tab navigation

    func testAllTabsAccessible() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        for label in ["Search", "My List", "Our List", "History", "Profile"] {
            XCTAssertTrue(tabBar.buttons[label].exists, "Tab '\(label)' not found")
        }
    }

    func testProfileTabShowsName() {
        app.tabBars.buttons["Profile"].tap()
        // The navigation title "Profile" should appear.
        let title = app.navigationBars["Profile"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
    }
}
