# Backend Guide

Keep Telebirr secrets on your server. The Flutter package only needs the
`receiveCode` returned by your backend.

## Simple Flow

1. Mobile app sends title and amount to your backend.
2. Backend applies Fabric Token with Telebirr.
3. Backend creates an in-app order with Telebirr.
4. Backend returns `receiveCode` to Flutter.
5. Flutter starts the Telebirr SDK.
6. Backend receives `notify_url`.
7. Backend verifies with `queryOrder` if needed.

## What The Backend Must Do

The backend owns the sensitive Telebirr REST flow:

- Store Fabric App ID, App Secret, merchant App ID, short code, and private key.
- Request a Fabric Token from Telebirr.
- Build the create-order payload.
- Sign the request with the private key.
- Send create-order to Telebirr.
- Return only `merchantOrderId` and `receiveCode` to Flutter.
- Receive `notify_url` from Telebirr after payment.
- Use `queryOrder` to confirm payment if the app needs a final status.

The Flutter app should never receive the App Secret or private key.

## Why receiveCode Matters

`receiveCode` is the payment instruction created by Telebirr for one order. It
contains the payment product, short code, amount, token-like order data, and
expiry period in the Telebirr-defined format.

The Flutter package passes this value to the native SDK unchanged. If the
`receiveCode` is expired, created for the wrong environment, or created with the
wrong merchant credentials, the native SDK may open but payment can fail.

## App Callback Vs Backend Confirmation

The SDK callback is useful for immediate UI:

- success screen
- cancelled message
- app-not-installed message
- parameter error message

Your backend confirmation is the source of truth:

- `notify_url` is Telebirr's server-to-server payment notification.
- `queryOrder` can verify an order when callback delivery fails or the app
  needs a fresh status.

## Example Create Order Response

```json
{
  "success": true,
  "merchantOrderId": "1705460512562",
  "receiveCode": "TELEBIRR$BUYGOODS$100100306$12.00$080075a4e3213924de2b3b84ad3cac0a6a6001$120m"
}
```

## Laravel Route Shape

```php
Route::post('/telebirr/create-order', function (Request $request) {
    $request->validate([
        'amount' => ['required', 'numeric', 'min:1'],
        'title' => ['required', 'string', 'max:128'],
    ]);

    // 1. Apply Fabric Token with your Fabric App ID and App Secret.
    // 2. Create the order with your merchant App ID, short code, notify_url,
    //    return_url, nonce, timestamp, and RSA signature.
    // 3. Return only safe response values to the app.

    return response()->json([
        'success' => true,
        'merchantOrderId' => $merchantOrderId,
        'receiveCode' => $receiveCode,
    ]);
});
```

## Never Put These In Flutter

- App Secret.
- Private key.
- RSA signing.
- Fabric Token request.
- createOrder request.
- queryOrder request.
- notify_url handling.

## Local Device Testing

Run your backend on the local network:

```sh
php artisan serve --host=0.0.0.0 --port=8000
```

Find your computer IP:

```sh
ipconfig getifaddr en0
```

Then use this in the example app:

```text
http://YOUR_LAN_IP:8000/api/telebirr/create-order
```
