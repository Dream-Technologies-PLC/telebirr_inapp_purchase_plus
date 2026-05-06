# What This Package Does

`telebirr_inapp_purchase_plus` is a Flutter-first wrapper around the official
Telebirr InApp Purchase native SDK.

## Automatic Package Work

- Validates `appId`, `shortCode`, `receiveCode`, and `returnApp` in Dart.
- Starts Telebirr payment from Flutter using one method call.
- Bridges Android SDK callbacks to Flutter.
- Bridges iOS SDK callbacks to Flutter.
- Maps common SDK result codes into `TelebirrPaymentResult`.
- Provides `paymentResultStream` for apps that prefer callback streams.
- Checks whether the Telebirr app is installed.
- Includes Android manifest permission and package visibility.
- Includes Android consumer ProGuard rules.
- Provides `Telebirr.initialize(...)` to generate or accept a return scheme.
- Provides `doctor` diagnostics for optional setup validation.

## Developer Work

- Create the Ethio Telecom developer account and get approved.
- Build a backend create-order endpoint.
- Keep App Secret and private key on the backend.
- Return `receiveCode` from backend to Flutter.
- Confirm final payment on backend using `notify_url` or `queryOrder`.
