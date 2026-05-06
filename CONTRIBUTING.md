# Contributing

Thanks for improving `telebirr_inapp_purchase_plus`.

## Local Setup

1. Install the latest stable Flutter SDK.
2. Place Telebirr Android AAR files in `android/libs/`.
3. Place `EthiopiaPaySDK.framework` in `ios/Frameworks/` if you are testing iOS.
4. Run `flutter pub get`.
5. Run `flutter analyze` and `flutter test`.

## Security Rules

Do not add merchant secrets, private keys, signing code, Fabric Token calls,
createOrder calls, queryOrder calls, or notify_url handlers to this Flutter
package. Those belong on a trusted backend.

## Pull Requests

Keep changes focused, document native setup changes, and include tests for Dart
mapping or validation behavior whenever possible.
