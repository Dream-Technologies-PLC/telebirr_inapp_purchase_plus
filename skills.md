# skills.md

## Best Package Description

`telebirr_inapp_purchase_plus` is the Flutter client SDK for Telebirr InApp
Purchase. Use it inside an existing Flutter app to open the native Telebirr
payment experience after a secure backend has created an order and returned a
`receiveCode`.

Copy this file into an existing Flutter app to guide an AI coding assistant while
adding Telebirr InApp payments with `telebirr_inapp_purchase_plus`.

This file is only for adding Telebirr payments to an existing Flutter app.

## AI Must Ask First

Before changing code, ask the developer for these values:

- Backend create-order URL.
- Merchant App ID.
- Business Short Code.
- Return app scheme.
- Target environment: `test` or `production`.
- Existing app state management pattern.
- Screen or checkout flow where payment should be added.

Also confirm:

- The backend already returns `receiveCode`.
- The Telebirr customer app or testbed app is installed on the test device.
- For a real phone, the backend URL is reachable from the phone.
- Final payment confirmation will be handled by the backend.

## Developer Actions Before AI Starts

The developer must:

- Provide the backend create-order endpoint.
- Provide safe non-secret merchant values needed by Flutter.
- Confirm whether the app is testing on simulator, emulator, or real device.
- Confirm the return app scheme to use.
- Confirm where payment success, cancellation, and failure should navigate.

## Goal

Add Telebirr InApp payment to the current Flutter app with the smallest safe
change set.

The app must:

1. Call its backend create-order endpoint.
2. Receive `receiveCode`.
3. Initialize Telebirr.
4. Start payment with `Telebirr.pay(...)`.
5. Show payment callback status to the user.
6. Let the backend confirm final payment through `notify_url` or `queryOrder`.

## Install

Add to `pubspec.yaml`:

```yaml
dependencies:
  telebirr_inapp_purchase_plus: ^1.0.2
```

Then run:

```bash
flutter pub get
```

## Flutter Integration

Use this API:

```dart
await Telebirr.initialize(
  appId: 'YOUR_MERCHANT_APP_ID',
  shortCode: 'YOUR_SHORT_CODE',
  returnScheme: 'yourappscheme',
  environment: TelebirrEnvironment.test,
);

final result = await Telebirr.pay(receiveCode: receiveCodeFromBackend);
```

Use `TelebirrEnvironment.production` only when the backend is also configured
for production.

## Backend Contract

The Flutter app should call an existing backend endpoint such as:

```text
POST /api/telebirr/create-order
```

Request body:

```json
{
  "title": "Example order",
  "amount": "12.00"
}
```

Expected response:

```json
{
  "success": true,
  "merchantOrderId": "ORDER_ID",
  "receiveCode": "TELEBIRR$BUYGOODS$YOUR_SHORT_CODE$12.00$PREPAY_ID$120m"
}
```

## UI Behavior

Add or update payment UI to include:

- Loading state while creating order.
- Loading state while starting payment.
- Error message area.
- Success message area.
- Display of last SDK callback result.
- Retry option for create-order failures.

## Security Rules

- Do not add App Secret, private key, Fabric Token, createOrder, queryOrder, or notify_url logic to Flutter.
- Do not hardcode real merchant credentials in source code.
- Do not commit real `receiveCode` values.
- Flutter SDK callback is not final payment confirmation.
- Final payment status must come from the backend.

## Common Existing-App Wiring

If the app already has an API client, add a method like:

```dart
Future<String> createTelebirrOrder({
  required String title,
  required String amount,
});
```

That method should return only `receiveCode` or a typed object containing
`merchantOrderId` and `receiveCode`.

If the app already has state management, integrate payment state into the
existing pattern instead of creating a new architecture.

## Device Testing

For a real phone, never use backend URL `localhost`.

Use the computer LAN IP:

```text
http://192.168.x.x:8001/api/telebirr/create-order
```

For production, use HTTPS.
