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
