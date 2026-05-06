package com.telebirr.plus.telebirr_inapp_purchase_plus

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.fragment.app.FragmentActivity
import com.huawei.ethiopia.pay.sdk.api.core.data.PayInfo
import com.huawei.ethiopia.pay.sdk.api.core.listener.PayCallback
import com.huawei.ethiopia.pay.sdk.api.core.utils.PaymentManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class TelebirrInappPurchasePlusPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware {

    private lateinit var applicationContext: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: FragmentActivity? = null
    private var eventSink: EventChannel.EventSink? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        PaymentManager.getInstance().setPayCallback(createPayCallback())
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
            "getApplicationId" -> result.success(applicationContext.packageName)
            "isTelebirrInstalled" -> result.success(isPackageInstalled(TELEBIRR_PACKAGE_NAME))
            "startPay" -> startPay(call, result)
            else -> result.notImplemented()
        }
    }

    private fun startPay(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("PAYMENT_IN_PROGRESS", "A Telebirr payment is already in progress.", null)
            return
        }

        val appId = call.argument<String>("appId")?.trim().orEmpty()
        val shortCode = call.argument<String>("shortCode")?.trim().orEmpty()
        val receiveCode = call.argument<String>("receiveCode")?.trim().orEmpty()
        val returnApp = call.argument<String>("returnApp")?.trim().orEmpty()

        val validationError = validate(appId, shortCode, receiveCode, returnApp)
        if (validationError != null) {
            result.error("PARAMETER_ERROR", validationError, -2)
            return
        }

        val hostActivity = activity
        if (hostActivity == null) {
            result.error(
                "NO_ACTIVITY",
                "Telebirr payment requires an attached FlutterFragmentActivity.",
                null
            )
            return
        }

        if (!isPackageInstalled(TELEBIRR_PACKAGE_NAME)) {
            val response = paymentResult(-10, "Telebirr payment app is not installed")
            emit(response)
            result.success(response)
            return
        }

        try {
            val builder = PayInfo.Builder()
                .setAppId(appId)
                .setShortCode(shortCode)
                .setReceiveCode(receiveCode)

            setReturnAppIfSupported(builder, returnApp)
            val payInfo = builder.build()

            pendingResult = result
            PaymentManager.getInstance().setPayCallback(createPayCallback())
            PaymentManager.getInstance().pay(hostActivity, payInfo)
        } catch (exception: Throwable) {
            pendingResult = null
            result.error(
                "PAYMENT_ERROR",
                exception.message ?: "Telebirr SDK failed to start payment.",
                exception.javaClass.name
            )
        }
    }

    private fun createPayCallback(): PayCallback {
        return object : PayCallback {
            override fun onPayCallback(code: Int, errMsg: String?) {
                val response = paymentResult(code, errMsg)
                activity?.runOnUiThread {
                    emit(response)
                    pendingResult?.success(response)
                    pendingResult = null
                } ?: run {
                    emit(response)
                    pendingResult?.success(response)
                    pendingResult = null
                }
            }
        }
    }

    private fun setReturnAppIfSupported(builder: PayInfo.Builder, returnApp: String) {
        try {
            val method = builder.javaClass.getMethod("setReturnApp", String::class.java)
            method.invoke(builder, returnApp)
        } catch (_: NoSuchMethodException) {
            // The provided UAT AAR does not expose setReturnApp; prod does.
        }
    }

    private fun validate(
        appId: String,
        shortCode: String,
        receiveCode: String,
        returnApp: String
    ): String? {
        if (appId.isBlank()) return "appId is required."
        if (shortCode.isBlank()) return "shortCode is required."
        if (receiveCode.isBlank()) return "receiveCode is required."
        if (!receiveCode.startsWith("TELEBIRR\$")) return "receiveCode must start with TELEBIRR\$."
        if (returnApp.isBlank()) return "returnApp is required."
        return null
    }

    private fun paymentResult(code: Int, message: String?): Map<String, Any> {
        return mapOf(
            "code" to code,
            "message" to messageFor(code, message)
        )
    }

    private fun messageFor(code: Int, message: String?): String {
        if (!message.isNullOrBlank()) return message
        return when (code) {
            0 -> "Payment successful"
            -2 -> "Telebirr payment parameter error"
            -3 -> "Payment cancelled"
            -10 -> "Telebirr payment app is not installed"
            -11 -> "Current Telebirr app version does not support this function"
            else -> "Unknown Telebirr payment error"
        }
    }

    private fun emit(response: Map<String, Any>) {
        eventSink?.success(response)
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                applicationContext.packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                applicationContext.packageManager.getPackageInfo(packageName, 0)
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pendingResult = null
        eventSink = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    private companion object {
        const val METHOD_CHANNEL_NAME = "telebirr_inapp_purchase_plus/methods"
        const val EVENT_CHANNEL_NAME = "telebirr_inapp_purchase_plus/events"
        const val TELEBIRR_PACKAGE_NAME = "cn.tydic.ethiopay"
    }
}
