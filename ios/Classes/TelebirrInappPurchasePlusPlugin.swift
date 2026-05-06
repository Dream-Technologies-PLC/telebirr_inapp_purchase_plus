import EthiopiaPaySDK
import Flutter
import UIKit

public class TelebirrInappPurchasePlusPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, EthiopiaPayManagerDelegate {
  private var eventSink: FlutterEventSink?
  private var pendingResult: FlutterResult?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = TelebirrInappPurchasePlusPlugin()
    let methodChannel = FlutterMethodChannel(
      name: "telebirr_inapp_purchase_plus/methods",
      binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(
      name: "telebirr_inapp_purchase_plus/events",
      binaryMessenger: registrar.messenger())

    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    registrar.addApplicationDelegate(instance)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getApplicationId":
      result(Bundle.main.bundleIdentifier)
    case "isTelebirrInstalled":
      result(isTelebirrInstalled())
    case "startPay":
      startPay(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startPay(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(
        code: "PAYMENT_IN_PROGRESS",
        message: "A Telebirr payment is already in progress.",
        details: nil))
      return
    }

    guard
      let arguments = call.arguments as? [String: Any],
      let appId = arguments["appId"] as? String,
      let shortCode = arguments["shortCode"] as? String,
      let receiveCode = arguments["receiveCode"] as? String,
      let returnApp = arguments["returnApp"] as? String
    else {
      result(FlutterError(
        code: "PARAMETER_ERROR",
        message: "appId, shortCode, receiveCode, and returnApp are required.",
        details: -2))
      return
    }

    if let validationError = validate(
      appId: appId,
      shortCode: shortCode,
      receiveCode: receiveCode,
      returnApp: returnApp)
    {
      result(FlutterError(code: "PARAMETER_ERROR", message: validationError, details: -2))
      return
    }

    pendingResult = result
    let manager = EthiopiaPayManager.shared()
    manager.delegate = self
    manager.startPay(
      withAppId: appId,
      shortCode: shortCode,
      receiveCode: receiveCode,
      returnAppScheme: returnApp)
  }

  private func validate(
    appId: String,
    shortCode: String,
    receiveCode: String,
    returnApp: String
  ) -> String? {
    if appId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "appId is required."
    }
    if shortCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "shortCode is required."
    }
    if receiveCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "receiveCode is required."
    }
    if !receiveCode.hasPrefix("TELEBIRR$") {
      return "receiveCode must start with TELEBIRR$."
    }
    if returnApp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "returnApp is required."
    }
    return nil
  }

  private func isTelebirrInstalled() -> Bool {
    guard let url = URL(string: "telebirrcustomerApp://") else {
      return false
    }
    return UIApplication.shared.canOpenURL(url)
  }

  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    EthiopiaPayManager.shared().handleOpen(url)
    return false
  }

  public func payResultCallback(withCode code: Int, msg: String) {
    finish(code: code, message: msg)
  }

  private func finish(code: Int, message: String?) {
    let response = paymentResult(code: code, message: message)
    eventSink?(response)
    pendingResult?(response)
    pendingResult = nil
  }

  private func paymentResult(code: Int, message: String?) -> [String: Any] {
    return [
      "code": code,
      "message": messageFor(code: code, message: message),
    ]
  }

  private func messageFor(code: Int, message: String?) -> String {
    if let message = message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return message
    }
    switch code {
    case 0:
      return "Payment successful"
    case -2:
      return "Telebirr payment parameter error"
    case -3:
      return "Payment cancelled"
    case -10:
      return "Telebirr payment app is not installed"
    case -11:
      return "Current Telebirr app version does not support this function"
    default:
      return "Unknown Telebirr payment error"
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
