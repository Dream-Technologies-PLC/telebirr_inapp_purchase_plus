import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telebirr_inapp_purchase_plus/telebirr_inapp_purchase_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('telebirr_inapp_purchase_plus/methods');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps native payment result flags', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'startPay');
      return <String, Object?>{
        'code': -3,
        'message': 'cancelled by user',
      };
    });

    final result = await TelebirrInAppPurchasePlus.startPay(
      const TelebirrPaymentRequest(
        appId: 'app123',
        shortCode: '100100306',
        receiveCode: 'TELEBIRR\$BUYGOODS\$100100306\$12.00\$abc\$120m',
        returnApp: 'example',
      ),
    );

    expect(result.isCancelled, isTrue);
    expect(result.isSuccess, isFalse);
    expect(result.message, 'cancelled by user');
  });

  test('checks Telebirr installation through platform', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'isTelebirrInstalled');
      return true;
    });

    expect(await TelebirrInAppPurchasePlus.isTelebirrInstalled(), isTrue);
  });

  test('rejects invalid receiveCode before native call', () async {
    expect(
      () => TelebirrInAppPurchasePlus.startPay(
        const TelebirrPaymentRequest(
          appId: 'app123',
          shortCode: '100100306',
          receiveCode: 'bad',
          returnApp: 'example',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('high-level Telebirr API requires initialize before pay', () async {
    expect(
      () => Telebirr.pay(
        receiveCode: 'TELEBIRR\$BUYGOODS\$100100306\$12.00\$abc\$120m',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('high-level Telebirr API initializes and pays with generated scheme',
      () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getApplicationId') {
        return 'com.example.shop';
      }
      if (call.method == 'startPay') {
        return <String, Object?>{
          'code': 0,
          'message': 'ok',
        };
      }
      return null;
    });

    await Telebirr.initialize(
      appId: 'app123',
      shortCode: '100100306',
    );

    final result = await Telebirr.pay(
      receiveCode: 'TELEBIRR\$BUYGOODS\$100100306\$12.00\$abc\$120m',
    );

    expect(result.isSuccess, isTrue);
    final startPayCall = calls.singleWhere((call) => call.method == 'startPay');
    final args = Map<dynamic, dynamic>.from(startPayCall.arguments as Map);
    expect(args['returnApp'], 'telebirr-com-example-shop');
    expect(args['appId'], 'app123');
  });
}
