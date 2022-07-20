package com.auth0.sample

import android.content.Context
import android.content.Intent
import android.widget.Button
import android.widget.EditText
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import org.hamcrest.CoreMatchers.notNullValue
import org.hamcrest.MatcherAssert.assertThat
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class SmokeTest {
    private var externalsDir: File? = null
    private val device: UiDevice
    private val PACKAGE_NAME = "com.auth0.sample"
    private val LOGIN_BUTTON = "Login"
    private val LOGOUT_BUTTON = "Logout"
    private val UL_BUTTON = "Log In"
    private val TIMEOUT = 30000L

    init {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        device = UiDevice.getInstance(instrumentation)
    }

    @Before
    fun launchApp() {
        device.pressHome()

        val launcherPackage: String = device.launcherPackageName
        assertThat(launcherPackage, notNullValue())
        device.wait(Until.hasObject(By.pkg(launcherPackage).depth(0)), TIMEOUT)

        // Launch the app
        val context = ApplicationProvider.getApplicationContext<Context>()
        val intent = context.packageManager.getLaunchIntentForPackage(PACKAGE_NAME)?.apply {
            // Clear out any previous instances
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
        }
        context.startActivity(intent)
        externalsDir = Environment.getExternalStoragePublicDirectory(DIRECTORY_PICTURES);

        // Wait for the app to appear
        device.wait(Until.hasObject(By.pkg(PACKAGE_NAME).depth(0)), TIMEOUT)
    }

    @Test
    fun loginAndLogout() {
        // Start login
        val loginButton = By.clazz(Button::class.qualifiedName).descContains(LOGIN_BUTTON)
        device.wait(Until.hasObject(loginButton), TIMEOUT)

        if (externalsDir != null) {
            device.takeScreenshot(File(externalsDir?.absolutePath, "test0.png"));
        }

        device.findObject(loginButton).click()

        // Fill login form
        val ulButton = By.clazz(Button::class.qualifiedName).textContains(UL_BUTTON)
        device.wait(Until.hasObject(ulButton), TIMEOUT)
        val textInputs = By.clazz(EditText::class.qualifiedName)
        device.wait(Until.hasObject(textInputs), TIMEOUT)
        val emailInput = device.findObjects(textInputs).first()
        emailInput.text = BuildConfig.USER_EMAIL
        val passwordInput = device.findObjects(textInputs).last()
        passwordInput.text = BuildConfig.USER_PASSWORD

        if (externalsDir != null) {
            device.takeScreenshot(File(externalsDir?.absolutePath, "test1.png"));
        }

        device.pressEnter()
        device.findObject(ulButton).click()

        // Logout
        val logoutButton = By.clazz(Button::class.qualifiedName).descContains(LOGOUT_BUTTON)
        device.wait(Until.hasObject(logoutButton), TIMEOUT)

        if (externalsDir != null) {
            device.takeScreenshot(File(externalsDir?.absolutePath, "test2.png"));
        }
        device.findObject(logoutButton).click()
        device.wait(Until.hasObject(loginButton), TIMEOUT)
        assertThat(device.findObject(loginButton), notNullValue())
    }
}