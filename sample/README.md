# Flutter sample application

This sample application demonstrates the integration of the Auth0 Flutter SDK into a Flutter application. The sample is a companion to the [Auth0 Flutter Quickstart](https://auth0.com/docs/quickstart/native/flutter).


## Requirements

- Flutter 3+
- Xcode 13+ (for iOS)
- Android Studio 4+ (for Android)

## Configure Auth0 Application
Go to the settings page of your [Auth0 application](https://manage.auth0.com/#/applications/) and add the corresponding URL to **Allowed Callback URLs** and **Allowed Logout URLs**, according to the application target you want to run. If you are using a [custom domain](https://auth0.com/docs/customize/custom-domains), replace `YOUR_AUTH0_DOMAIN` with the value of your custom domain instead of the value from the settings page.

**Android**

```
SCHEME://YOUR_AUTH0_DOMAIN/android/YOUR_PACKAGE_NAME/callback
```

**iOS**
```
YOUR_BUNDLE_ID://YOUR_AUTH0_DOMAIN/ios/YOUR_BUNDLE_ID/callback
```

## Configure Auth0 Flutter
The sample application uses [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) for its configuration. Rename `.env.example` to `.env` and provide the appropriate **Domain** and **Client Id**. Optionally, when using Android, you can configure the scheme as well. This can be set to a custom scheme, or `https` if you want to use [Android App Links](https://auth0.com/docs/applications/enable-android-app-links). You can read more about setting this value in the [Auth0.Android SDK README](https://github.com/auth0/Auth0.Android#a-note-about-app-deep-linking).

```
AUTH0_DOMAIN={DOMAIN}
AUTH0_CLIENT_ID={CLIENT_ID}
# AUTH0_CUSTOM_SCHEME=SCHEME
```

### Android

In the sample, we are using values referenced from `strings.xml`. Rename `strings.xml.example` to `strings.xml` and ensure to set the correct values.

- `com_auth0_domain`: The domain of your Auth0 tenant. Generally, you can find this in the Auth0 Dashboard under your Application's Settings in the Domain field. If you are using a custom domain, you should set this to the value of your custom domain instead.
- `com_auth0_scheme`: The scheme to use. Can be a custom scheme, or `https` if you want to use [Android App Links](https://auth0.com/docs/applications/enable-android-app-links). You can read more about setting this value in the [Auth0.Android SDK README](https://github.com/auth0/Auth0.Android#a-note-about-app-deep-linking).

### iOS

The sample has already configured the required **Url Types**  to ensure the callback and logout URLs can reach the application, so there is nothing to configure in order to run the sample on iOS.

## Run the sample

To run the project, use the [Flutter CLI's](https://docs.flutter.dev/reference/flutter-cli) `run` command:

```
flutter run
```

Ensure you have at least one emulator running. If you have multiple running, the CLI will prompt you to select the one to run the application on.

## Compile the sample

To compile the project, use the [Flutter CLI's](https://docs.flutter.dev/reference/flutter-cli) `build` command, including the platform you want to target.

```
flutter build apk
flutter build ios
```

## Issue Reporting

For general support or usage questions, use the [Auth0 Community](https://community.auth0.com/c/sdks/5) forums or raise a [support ticket](https://support.auth0.com/). Only [raise an issue](https://github.com/auth0-samples/auth0-flutter-samples/issues) if you have found a bug or want to request a feature.

**Do not report security vulnerabilities on the public GitHub issue tracker.** The [Responsible Disclosure Program](https://auth0.com/responsible-disclosure-policy) details the procedure for disclosing security issues.

## What is Auth0?

Auth0 helps you to:

* Add authentication with [multiple sources](https://auth0.com/docs/authenticate/identity-providers), either social identity providers such as **Google, Facebook, Microsoft Account, LinkedIn, GitHub, Twitter, Box, Salesforce** (amongst others), or enterprise identity systems like **Windows Azure AD, Google Apps, Active Directory, ADFS, or any SAML identity provider**.
* Add authentication through more traditional **[username/password databases](https://auth0.com/docs/authenticate/database-connections/custom-db)**.
* Add support for **[linking different user accounts](https://auth0.com/docs/manage-users/user-accounts/user-account-linking)** with the same user.
* Support for generating signed [JSON Web Tokens](https://auth0.com/docs/secure/tokens/json-web-tokens) to call your APIs and **flow the user identity** securely.
* Analytics of how, when, and where users are logging in.
* Pull data from other sources and add it to the user profile through [JavaScript Actions](https://auth0.com/docs/customize/actions).

**Why Auth0?** Because you should save time, be happy, and focus on what really matters: building your product.

## License

This project is licensed under Apache License 2.0. See the [LICENSE](../LICENSE) file for more information.
