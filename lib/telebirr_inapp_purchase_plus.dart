import 'dart:async';

import 'package:flutter/services.dart';

enum TelebirrEnvironment {
  test,
  production,
}

class TelebirrPaymentRequest {
  final String appId;
  final String shortCode;
  final String receiveCode;
  final String returnApp;
  final TelebirrEnvironment environment;

  const TelebirrPaymentRequest({
    required this.appId,
    required this.shortCode,
    required this.receiveCode,
    required this.returnApp,
    this.environment = TelebirrEnvironment.test,
  });

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

class TelebirrPaymentResult {
  final int code;
  final String message;
  final bool isSuccess;
  final bool isCancelled;
  final bool isAppNotInstalled;
  final bool isUnsupportedVersion;
  final bool isParameterError;
  final Map<String, dynamic>? raw;

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

  factory TelebirrPaymentResult.fromMap(Map<dynamic, dynamic> map) {
    final code = _asInt(map['code']) ?? -1;
    return TelebirrPaymentResult.fromCode(
      code: code,
      message: map['message']?.toString() ?? map['errMsg']?.toString(),
      raw: Map<String, dynamic>.from(map),
    );
  }

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

class TelebirrInAppPurchasePlus {
  static const MethodChannel _methodChannel = MethodChannel(
    'telebirr_inapp_purchase_plus/methods',
  );
  static const EventChannel _eventChannel = EventChannel(
    'telebirr_inapp_purchase_plus/events',
  );

  static Stream<TelebirrPaymentResult>? _paymentResultStream;

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

  static Stream<TelebirrPaymentResult> get paymentResultStream {
    return _paymentResultStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => TelebirrPaymentResult.fromMap(event as Map));
  }

  static Future<bool> isTelebirrInstalled() async {
    return await _methodChannel.invokeMethod<bool>('isTelebirrInstalled') ??
        false;
  }

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
