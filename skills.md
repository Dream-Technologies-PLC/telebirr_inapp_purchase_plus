# skills.md

Copy this file into an existing Flutter app to guide an AI coding assistant while
adding Telebirr InApp payments with `telebirr_inapp_purchase_plus`.

This file is only for adding Telebirr payments to an existing Flutter app.

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
