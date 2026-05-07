# skills.md

Use this file as AI coding instructions when integrating or modifying
`telebirr_inapp_purchase_plus`.

## Package Role

This Flutter package starts Telebirr InApp Purchase payments from a Flutter app.
It must only receive a `receiveCode` created by a secure backend.

The Flutter package must not implement:

- Fabric Token requests
- Create Order requests
- Query Order requests
- RSA signing
- App Secret storage
- Private key storage
- notify_url handling

Those belong on the backend.

## Correct Flutter Flow

1. Flutter calls the backend create-order endpoint.
2. Backend returns `receiveCode`.
3. Flutter initializes Telebirr.
4. Flutter calls `Telebirr.pay(receiveCode: ...)`.
5. Flutter shows SDK callback result.
6. Backend confirms final payment through `notify_url` or `queryOrder`.

## Preferred API

Use the high-level API:

```dart
await Telebirr.initialize(
  appId: 'YOUR_MERCHANT_APP_ID',
  shortCode: 'YOUR_SHORT_CODE',
  returnScheme: 'yourappscheme',
  environment: TelebirrEnvironment.test,
);

final result = await Telebirr.pay(receiveCode: receiveCodeFromBackend);
```

Use `TelebirrInAppPurchasePlus.startPay(...)` only for legacy migration.

## Security Rules

- Never hardcode real merchant credentials in examples or tests.
- Never commit App Secret, private key, Fabric App ID, Merchant App ID, Short Code, or real receiveCode values.
- Example values must use placeholders such as `YOUR_MERCHANT_APP_ID`.
- Payment finality must come from backend confirmation, not only Flutter SDK callback.

## Native Integration Rules

Android:

- Keep Kotlin plugin code on modern Flutter embedding.
- Keep ActivityAware lifecycle handling safe.
- Return readable errors when activity is unavailable.
- Keep EventChannel callback streaming stable.
- Preserve ProGuard rules for Telebirr SDK classes.

iOS:

- Keep Swift plugin code compatible with Flutter plugin registration.
- Keep URL/deep-link return handling safe.
- Return clear SDK-not-available errors if native SDK is missing or not linked.

## Testing Checklist

Before release:

- Run `flutter analyze`.
- Run `flutter test`.
- Run `dart pub publish --dry-run`.
- Check no real credentials are present:

```bash
rg "APP_SECRET|PRIVATE_KEY|MIIE|YOUR_REAL|receiveCode"
```

## Backend Pairing

Recommended backend packages:

- Laravel: `dream-technologies/telebirr-laravel-plus`
- Node.js: `telebirr_plus`

Flutter should call the backend endpoint:

```text
POST /api/telebirr/create-order
```

Expected backend response:

```json
{
  "success": true,
  "merchantOrderId": "ORDER_ID",
  "receiveCode": "TELEBIRR$BUYGOODS$YOUR_SHORT_CODE$12.00$PREPAY_ID$120m"
}
```

