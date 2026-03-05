import XCTest

/// UI tests for the Authentication flow (Login ↔ Register toggle).
/// These tests do NOT hit Firebase — they verify UI element presence,
/// navigation, and validation feedback using the simulator.
final class AuthFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Inject a flag so the app can skip the Firebase auth listener
        // and always start on the Auth screen during UI tests.
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    // MARK: - Login screen presence

    func testLoginScreenShowsExpectedElements() {
        // The app opens on the auth screen during UI tests.
        // Verify key elements are present.
        XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.buttons["Sign In"].exists)
    }

    // MARK: - Toggle to Register

    func testToggleToRegister() {
        // Tap the "Don't have an account?" / "Create Account" toggle button.
        let registerToggle = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Create Account' OR label CONTAINS 'Register'")
        ).firstMatch

        XCTAssertTrue(registerToggle.waitForExistence(timeout: 5))
        registerToggle.tap()

        // Register screen should now show a "Display Name" field
        XCTAssertTrue(app.textFields["Display Name"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Create Account"].exists)
    }

    // MARK: - Toggle back to Login

    func testToggleBackToLogin() {
        let registerToggle = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Create Account' OR label CONTAINS 'Register'")
        ).firstMatch
        XCTAssertTrue(registerToggle.waitForExistence(timeout: 5))
        registerToggle.tap()

        // Now tap "Already have an account?" / "Sign In" toggle
        let loginToggle = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Sign In' OR label CONTAINS 'Already have'")
        ).firstMatch
        XCTAssertTrue(loginToggle.waitForExistence(timeout: 3))
        loginToggle.tap()

        // Should be back on the login screen
        XCTAssertTrue(app.buttons["Sign In"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["Display Name"].exists)
    }

    // MARK: - Sign in with empty fields

    func testSignInWithEmptyFieldsShowsNoNavigation() {
        // Tap Sign In without entering credentials — app should stay on auth screen.
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5))
        signInButton.tap()

        // The login screen should still be present (not navigated away).
        XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: 3))
    }
}
