# Native Setup Details

Most apps should not need to write Telebirr native payment code. The Flutter
package owns native SDK artifacts, platform channels, native SDK calls,
callback forwarding, and result mapping.

## Android

The plugin declares:

- Android `INTERNET` permission.
- Telebirr payment app package visibility.
- Consumer ProGuard rule:

```proguard
-keep class com.huawei.ethiopia.pay.sdk.api.core.** { *; }
```

The plugin also calls the native Telebirr payment SDK from Android and sends
results back to Dart through `EventChannel`.

## iOS

Use `returnScheme` in Dart:

```dart
await Telebirr.initialize(
  appId: 'YOUR_MERCHANT_APP_ID',
  shortCode: 'YOUR_SHORT_CODE',
  returnScheme: 'yourappscheme',
);
```

The plugin registers an application delegate and forwards `openURL` to the SDK.
If your app has custom AppDelegate or SceneDelegate URL routing, make sure it
allows the Telebirr return URL to reach Flutter plugins.

Run diagnostics when something feels off:

```sh
dart run telebirr_inapp_purchase_plus:doctor
```
