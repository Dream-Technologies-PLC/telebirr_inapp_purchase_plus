# How It Works

This package connects Flutter to the official Telebirr InApp Purchase SDK. It
does not create Telebirr orders and does not store secrets.

## Full Payment Flow

1. User taps buy in your Flutter app.
2. Flutter calls your backend create-order endpoint.
3. Backend requests a Fabric Token from Telebirr.
4. Backend creates the in-app order with Telebirr.
5. Telebirr returns `receiveCode`.
6. Backend returns `receiveCode` to Flutter.
7. Flutter calls `TelebirrInAppPurchasePlus.startPay`.
8. The plugin calls the native Android or iOS Telebirr SDK.
9. The native SDK opens the Telebirr payment app.
10. User pays or cancels.
11. Flutter receives the SDK callback.
12. Backend receives `notify_url`.
13. Backend verifies with `queryOrder` when needed.

## What This Package Does

- Validates `appId`, `shortCode`, `receiveCode`, and `returnApp`.
- Calls native Android/iOS Telebirr SDK.
- Returns a typed `TelebirrPaymentResult`.
- Provides a stream for callback events.
- Maps common Telebirr SDK error codes.

## What This Package Does Not Do

- Apply Fabric Token.
- Create orders.
- Query orders.
- Handle `notify_url`.
- Sign requests.
- Store App Secret.
- Store private key.

## Native Bridge

Android:

- Flutter sends `startPay` over `MethodChannel`.
- Kotlin builds `PayInfo`.
- Kotlin calls `PaymentManager.getInstance().pay(activity, payInfo)`.
- Kotlin sends SDK callback through `EventChannel`.

iOS:

- Flutter sends `startPay` over `MethodChannel`.
- Swift calls `EthiopiaPayManager.shared().startPay(...)`.
- Swift forwards open URL callbacks to Telebirr SDK.
- Swift sends SDK callback through `EventChannel`.

## Result Meaning

`TelebirrPaymentResult.isSuccess` means the native SDK returned success. For
final order state, use backend `notify_url` or `queryOrder`.
