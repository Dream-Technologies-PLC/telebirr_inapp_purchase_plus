# Native SDK Files

`telebirr_inapp_purchase_plus` is designed so Flutter developers use the Dart
API instead of editing native Android or iOS payment code. The package ships
the native Telebirr SDK artifacts needed by the plugin.

The app integration flow is:

```dart
await Telebirr.initialize(
  appId: 'YOUR_MERCHANT_APP_ID',
  shortCode: 'YOUR_SHORT_CODE',
  returnScheme: 'yourappscheme',
  environment: TelebirrEnvironment.test,
);

final result = await Telebirr.pay(
  receiveCode: receiveCodeFromBackend,
);
```

## Android

The plugin owns:

- Telebirr Android SDK dependency wiring.
- MethodChannel and EventChannel.
- Telebirr SDK `startPay` bridge.
- Payment callback mapping.
- `INTERNET` permission.
- Telebirr app package visibility.
- Consumer ProGuard keep rules.

## iOS

The plugin owns:

- `EthiopiaPaySDK.framework` linking.
- MethodChannel and EventChannel.
- `EthiopiaPayManager` bridge.
- SDK callback mapping.
- `openURL` forwarding through the plugin application delegate.

Pass the same return scheme to `Telebirr.initialize(returnScheme: ...)` that
your app uses for URL returns. If omitted, the package generates one from the
bundle identifier.

If your app has custom AppDelegate or SceneDelegate URL routing, make sure it
does not swallow Telebirr return URLs before Flutter plugins receive them.
