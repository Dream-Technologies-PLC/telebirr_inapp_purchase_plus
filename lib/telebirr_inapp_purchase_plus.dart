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

/// Runtime configuration for the high-level [Telebirr] API.
///
/// Keep App Secret, private keys, Fabric Token, order creation, notify_url, and
/// queryOrder logic on your backend. This config contains only values required
/// by the native Telebirr SDK to open the payment screen.
class TelebirrConfig {
  /// Merchant App ID from the Ethio Telecom developer portal.
  final String appId;

  /// Merchant business short code.
  final String shortCode;

  /// Optional app return scheme. When omitted, the package generates a stable
  /// scheme from the Android application ID or iOS bundle identifier.
  final String? returnScheme;

  /// Native SDK environment.
  final TelebirrEnvironment environment;

  /// Enables package-side debug logs.
  final bool enableLogs;

  /// Creates Telebirr runtime configuration.
  const TelebirrConfig({
    required this.appId,
    required this.shortCode,
    this.returnScheme,
    this.environment = TelebirrEnvironment.test,
    this.enableLogs = false,
  });
}

/// Diagnostics returned by [Telebirr.doctor].
class TelebirrDiagnostics {
  /// Whether the current runtime checks passed.
  final bool isHealthy;

  /// Human-readable diagnostics messages.
  final List<String> messages;

  /// Generated or configured return scheme.
  final String? returnScheme;

  /// Android application ID or iOS bundle identifier.
  final String? applicationId;

  /// Creates diagnostics for Telebirr runtime setup.
  const TelebirrDiagnostics({
    required this.isHealthy,
    required this.messages,
    this.returnScheme,
    this.applicationId,
  });

  /// Converts diagnostics to a JSON-friendly map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'isHealthy': isHealthy,
      'messages': messages,
      'returnScheme': returnScheme,
      'applicationId': applicationId,
    };
  }
}

/// High-level plug-and-play Telebirr API.
///
/// Call [initialize] once, then call [pay] with a backend-created receiveCode.
class Telebirr {
  Telebirr._();

  static TelebirrConfig? _config;
  static String? _returnScheme;
  static String? _applicationId;

  /// Initializes Telebirr for this app.
  ///
  /// If [config.returnScheme] is omitted, the package generates a stable scheme
  /// from the host app package name or bundle identifier.
  static Future<void> initialize({
    required String appId,
    required String shortCode,
    String? returnScheme,
    TelebirrEnvironment environment = TelebirrEnvironment.test,
    bool enableLogs = false,
  }) async {
    final normalizedConfig = TelebirrConfig(
      appId: appId.trim(),
      shortCode: shortCode.trim(),
      returnScheme: returnScheme?.trim(),
      environment: environment,
      enableLogs: enableLogs,
    );
    _validateConfig(normalizedConfig);

    _applicationId = await TelebirrInAppPurchasePlus.getApplicationId();
    _returnScheme = _normalizeReturnScheme(
      normalizedConfig.returnScheme?.isNotEmpty == true
          ? normalizedConfig.returnScheme!
          : _generatedReturnScheme(_applicationId),
    );
    _config = normalizedConfig;

    _log('Initialized Telebirr with return scheme: $_returnScheme');
  }

  /// Starts Telebirr payment with a backend-created [receiveCode].
  static Future<TelebirrPaymentResult> pay({
    required String receiveCode,
  }) async {
    final config = _config;
    final returnScheme = _returnScheme;
    if (config == null || returnScheme == null) {
      throw StateError(
          'Call Telebirr.initialize(...) before Telebirr.pay(...).');
    }

    return TelebirrInAppPurchasePlus.startPay(
      TelebirrPaymentRequest(
        appId: config.appId,
        shortCode: config.shortCode,
        receiveCode: receiveCode,
        returnApp: returnScheme,
        environment: config.environment,
      ),
    );
  }

  /// Broadcast stream of Telebirr payment results.
  static Stream<TelebirrPaymentResult> get paymentResultStream {
    return TelebirrInAppPurchasePlus.paymentResultStream;
  }

  /// Returns true when the Telebirr payment app is installed.
  static Future<bool> isTelebirrInstalled() {
    return TelebirrInAppPurchasePlus.isTelebirrInstalled();
  }

  /// Performs lightweight runtime diagnostics.
  ///
  /// Full project-file diagnostics are available from:
  /// `dart run telebirr_inapp_purchase_plus:doctor`.
  static Future<TelebirrDiagnostics> doctor() async {
    final messages = <String>[];
    final applicationId =
        _applicationId ?? await TelebirrInAppPurchasePlus.getApplicationId();
    final returnScheme = _returnScheme ?? _generatedReturnScheme(applicationId);
    final installed = await isTelebirrInstalled();

    if (applicationId == null || applicationId.isEmpty) {
      messages.add('Could not detect application ID or bundle identifier.');
    } else {
      messages.add('Detected app ID: $applicationId');
    }
    messages.add('Return scheme: $returnScheme');
    messages.add(
      installed
          ? 'Telebirr app is installed.'
          : 'Telebirr app is not installed.',
    );

    return TelebirrDiagnostics(
      isHealthy: applicationId != null && applicationId.isNotEmpty,
      messages: messages,
      applicationId: applicationId,
      returnScheme: returnScheme,
    );
  }

  static void _validateConfig(TelebirrConfig config) {
    final errors = <String>[];
    if (config.appId.isEmpty) errors.add('appId is required');
    if (config.shortCode.isEmpty) errors.add('shortCode is required');
    if (config.returnScheme != null &&
        config.returnScheme!.isNotEmpty &&
        !_isValidScheme(config.returnScheme!)) {
      errors.add('returnScheme must be a valid URL scheme');
    }
    if (errors.isNotEmpty) {
      throw ArgumentError(errors.join(', '));
    }
  }

  static String _generatedReturnScheme(String? applicationId) {
    final id = applicationId?.trim();
    if (id == null || id.isEmpty) return 'telebirr-flutter-app';
    return 'telebirr-${id.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}'
        .toLowerCase();
  }

  static String _normalizeReturnScheme(String value) {
    return value.trim().replaceAll('://', '');
  }

  static bool _isValidScheme(String value) {
    return RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*$').hasMatch(value);
  }

  static void _log(String message) {
    if (_config?.enableLogs == true) {
      // ignore: avoid_print
      print('[telebirr] $message');
    }
  }
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

  /// Returns Android application ID or iOS bundle identifier.
  static Future<String?> getApplicationId() {
    return _methodChannel.invokeMethod<String>('getApplicationId');
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
