import XCTest

class SmokeTests: XCTestCase {
    private let email = ProcessInfo.processInfo.environment["USER_EMAIL"]!
    private let password = ProcessInfo.processInfo.environment["USER_PASSWORD"]!
    private let loginButton = "Login"
    private let logoutButton = "Logout"
    private let continueButton = "Continue"
    private let webLoginButton = "Log In"
    private let browserApp = "com.apple.Safari"
    private let timeout: TimeInterval = 30

    override func setUp() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment = ProcessInfo.processInfo.environment
        app.launch()
    }

    func testLogin() {
        clickButton()
        clickAlert()

        let browser = XCUIApplication(bundleIdentifier: browserApp)
        let browserWindow = browser
            .windows
            .firstMatch
            .webViews
            .firstMatch
        XCTAssertTrue(browserWindow.waitForExistence(timeout: timeout))

        let emailInput = browserWindow.textFields.firstMatch
        XCTAssertTrue(emailInput.waitForExistence(timeout: timeout))
        emailInput.click()
        emailInput.typeText(email)

        let passwordInput = browserWindow.secureTextFields.firstMatch
        passwordInput.click()
        passwordInput.typeText(password)

        browserWindow.buttons[webLoginButton].click()
        
        let app = XCUIApplication()
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: timeout))
    }

    func testLogout() {
        clickButton()
        clickAlert()

        let browser = XCUIApplication(bundleIdentifier: browserApp)
        let browserWindow = browser
            .windows
            .firstMatch
            .webViews
            .firstMatch
        XCTAssertTrue(browserWindow.waitForExistence(timeout: timeout))

        let sessionButton = browserWindow.staticTexts[email]
        XCTAssertTrue(sessionButton.waitForExistence(timeout: timeout))
        sessionButton.click()

        let app = XCUIApplication()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: timeout))

        sleep(5) // Wait for navigation to profile view

        clickButton()
        clickAlert()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: timeout))
    }
}

private extension SmokeTests {
    func clickButton() {
        let app = XCUIApplication()
        app.activate()

        let view = app.windows.firstMatch.groups.firstMatch
        let coordinate = view.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        coordinate.click()
    }

    func clickAlert() {
        let dialog = XCUIApplication(bundleIdentifier: "com.apple.UserNotificationCenter")
            .dialogs
            .firstMatch
        XCTAssertTrue(dialog.waitForExistence(timeout: timeout))

        let continueButton = dialog.buttons[continueButton]
        XCTAssertTrue(continueButton.waitForExistence(timeout: timeout))
        continueButton.click()
    }
}
