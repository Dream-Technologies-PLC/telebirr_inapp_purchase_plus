# Native Setup Details

Most Flutter developers should use the setup helper:

```sh
dart run telebirr_inapp_purchase_plus:telebirr_setup \
  --sdk-dir /path/to/TelebirrSDKFolder \
  --return-scheme yourappscheme
```

This page documents what the helper configures.

## Android

The helper copies the official Telebirr AAR files:

```text
android/libs/EthiopiaPaySdkModule-uat-release.aar
android/libs/EthiopiaPaySdkModule-prod-release.aar
```

It creates local Maven artifacts used by the plugin Gradle file and patches
common Kotlin/Java `MainActivity` files to use:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

The plugin already declares:

- Android `INTERNET` permission.
- Telebirr payment app package visibility.
- Consumer ProGuard rule:

```proguard
-keep class com.huawei.ethiopia.pay.sdk.api.core.** { *; }
```

## iOS

The helper copies:

```text
ios/Frameworks/EthiopiaPaySDK.framework
```

It also adds common `Info.plist` entries:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>telebirrcustomerApp</string>
</array>
```

and a URL type for your `--return-scheme`.

The plugin registers an application delegate and forwards `openURL` to the SDK.
If your app has custom AppDelegate or SceneDelegate URL routing, make sure it
allows the Telebirr return URL to reach Flutter plugins.
