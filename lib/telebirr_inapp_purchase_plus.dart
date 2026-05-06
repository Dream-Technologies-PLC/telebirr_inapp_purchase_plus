/// Flutter bridge for the official Telebirr InApp Purchase SDK.
///
/// The library starts native Telebirr payments with a backend-created
/// `receiveCode` and returns SDK callbacks as typed Dart results.
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// Telebirr InApp Purchase environment used by the native SDK.
enum TelebirrEnvironment {
  /// Telebirr UAT/testbed environment.
  test,

  /// Telebirr production environment.
  production,
}

/// Payment data required to open the Telebirr native payment app.
///
/// The [receiveCode] must come from your backend create-order endpoint. Do not
/// create or sign Telebirr orders in Flutter.
class TelebirrPaymentRequest {
  /// Merchant App ID from the Ethio Telecom developer portal.
  final String appId;

  /// Merchant business short code.
  final String shortCode;

  /// Telebirr receive code returned by your backend create-order endpoint.
  final String receiveCode;

  /// URL scheme used by Telebirr to return to your app.
  final String returnApp;

  /// Native SDK environment.
  final TelebirrEnvironment environment;

  /// Creates an immutable Telebirr payment request.
  const TelebirrPaymentRequest({
    required this.appId,
    required this.shortCode,
    required this.receiveCode,
    required this.returnApp,
    this.environment = TelebirrEnvironment.test,
  });

  /// Converts this request to the platform-channel payload.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'appId': appId,
      'shortCode': shortCode,
      'receiveCode': receiveCode,
      'returnApp': returnApp,
      'environment': environment.name,
    };
  }
}

/// Result returned by the Telebirr native SDK callback.
///
/// Use this for immediate UI feedback. Your backend `notify_url` or
/// `queryOrder` response should remain the final source of payment truth.
class TelebirrPaymentResult {
  /// Raw Telebirr SDK result code.
  final int code;

  /// Human-readable result message.
  final String message;

  /// True when [code] is `0`.
  final bool isSuccess;

  /// True when the customer cancelled payment.
  final bool isCancelled;

  /// True when the Telebirr payment app is not installed.
  final bool isAppNotInstalled;

  /// True when the installed Telebirr app does not support this function.
  final bool isUnsupportedVersion;

  /// True when Telebirr reported invalid payment parameters.
  final bool isParameterError;

  /// Original platform-channel payload, when available.
  final Map<String, dynamic>? raw;

  /// Creates an immutable Telebirr payment result.
  const TelebirrPaymentResult({
    required this.code,
    required this.message,
    required this.isSuccess,
    required this.isCancelled,
    required this.isAppNotInstalled,
    required this.isUnsupportedVersion,
    required this.isParameterError,
    this.raw,
  });

  /// Creates a result from a native SDK [code].
  factory TelebirrPaymentResult.fromCode({
    required int code,
    String? message,
    Map<String, dynamic>? raw,
  }) {
    return TelebirrPaymentResult(
      code: code,
      message: _messageFor(code, message),
      isSuccess: code == 0,
      isCancelled: code == -3,
      isAppNotInstalled: code == -10,
      isUnsupportedVersion: code == -11,
      isParameterError: code == -2,
      raw: raw,
    );
  }

  /// Creates a result from a platform-channel map.
  factory TelebirrPaymentResult.fromMap(Map<dynamic, dynamic> map) {
    final code = _asInt(map['code']) ?? -1;
    return TelebirrPaymentResult.fromCode(
      code: code,
      message: map['message']?.toString() ?? map['errMsg']?.toString(),
      raw: Map<String, dynamic>.from(map),
    );
  }

  /// Converts this result to a JSON-friendly map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'message': message,
      'isSuccess': isSuccess,
      'isCancelled': isCancelled,
      'isAppNotInstalled': isAppNotInstalled,
      'isUnsupportedVersion': isUnsupportedVersion,
      'isParameterError': isParameterError,
      if (raw != null) 'raw': raw,
    };
  }

  static String _messageFor(int code, String? message) {
    final trimmed = message?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return switch (code) {
      0 => 'Payment successful',
      -2 => 'Telebirr payment parameter error',
      -3 => 'Payment cancelled',
      -10 => 'Telebirr payment app is not installed',
      -11 => 'Current Telebirr app version does not support this function',
      _ => 'Unknown Telebirr payment error',
    };
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}

/// Flutter entry point for Telebirr InApp Purchase SDK payments.
class TelebirrInAppPurchasePlus {
  TelebirrInAppPurchasePlus._();

  static const MethodChannel _methodChannel = MethodChannel(
    'telebirr_inapp_purchase_plus/methods',
  );
  static const EventChannel _eventChannel = EventChannel(
    'telebirr_inapp_purchase_plus/events',
  );

  static Stream<TelebirrPaymentResult>? _paymentResultStream;

  /// Starts Telebirr payment using the native Android or iOS SDK.
  ///
  /// The [request.receiveCode] must be created by your backend before calling
  /// this method. Throws [ArgumentError] before native code is called when
  /// required fields are missing or invalid.
  static Future<TelebirrPaymentResult> startPay(
    TelebirrPaymentRequest request,
  ) async {
    _validateRequest(request);
    try {
      final response = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
        'startPay',
        request.toMap(),
      );
      return TelebirrPaymentResult.fromMap(response ?? <dynamic, dynamic>{});
    } on PlatformException catch (error) {
      return TelebirrPaymentResult.fromCode(
        code: _codeForPlatformError(error),
        message: error.message ?? error.details?.toString(),
        raw: <String, dynamic>{
          'platformCode': error.code,
          if (error.details != null) 'details': error.details,
        },
      );
    }
  }

  /// Broadcast stream of Telebirr native SDK callback results.
  static Stream<TelebirrPaymentResult> get paymentResultStream {
    return _paymentResultStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => TelebirrPaymentResult.fromMap(event as Map));
  }

  /// Returns whether the Telebirr payment app can be opened on this device.
  static Future<bool> isTelebirrInstalled() async {
    return await _methodChannel.invokeMethod<bool>('isTelebirrInstalled') ??
        false;
  }

  /// Returns the current Android or iOS platform version string.
  static Future<String?> getPlatformVersion() {
    return _methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  static void _validateRequest(TelebirrPaymentRequest request) {
    final errors = <String>[];
    if (request.appId.trim().isEmpty) {
      errors.add('appId is required');
    }
    if (request.shortCode.trim().isEmpty) {
      errors.add('shortCode is required');
    }
    if (request.receiveCode.trim().isEmpty) {
      errors.add('receiveCode is required');
    }
    if (!request.receiveCode.startsWith('TELEBIRR\$')) {
      errors.add('receiveCode must start with TELEBIRR\$');
    }
    if (request.returnApp.trim().isEmpty) {
      errors.add('returnApp is required');
    }
    if (errors.isNotEmpty) {
      throw ArgumentError(errors.join(', '));
    }
  }

  static int _codeForPlatformError(PlatformException error) {
    return switch (error.code) {
      'PARAMETER_ERROR' || 'INVALID_ARGUMENTS' => -2,
      'TELEBIRR_NOT_INSTALLED' => -10,
      'UNSUPPORTED_VERSION' => -11,
      _ => -1,
    };
  }
}
